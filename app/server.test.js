'use strict';

const assert = require('node:assert/strict');
const { once } = require('node:events');
const test = require('node:test');
const { createApplication, loadConfig } = require('./server');

test('configuration rejects an invalid backend URL', () => {
  assert.throws(
    () => loadConfig({ BACKEND_URL: 'not-a-url' }),
    /BACKEND_URL is invalid/
  );
});

test('health, order, alert webhook, and metrics endpoints form a valid smoke path', async (t) => {
  const config = loadConfig({
    BACKEND_URL: 'http://dependency:8080',
    STARTUP_DELAY_MS: '0',
    SHUTDOWN_DELAY_MS: '0'
  });
  const app = createApplication(config);
  app.server.listen(0, '127.0.0.1');
  await once(app.server, 'listening');
  t.after(() => new Promise((resolve) => app.server.close(resolve)));

  const address = app.server.address();
  const baseUrl = `http://127.0.0.1:${address.port}`;
  await new Promise((resolve) => setTimeout(resolve, 5));

  const ready = await fetch(`${baseUrl}/health/ready`);
  assert.equal(ready.status, 200);

  const order = await fetch(`${baseUrl}/api/orders`, { method: 'POST' });
  assert.equal(order.status, 202);
  assert.match((await order.json()).orderId, /^ord-/);

  const notification = await fetch(`${baseUrl}/api/alerts`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      receiver: 'incident-lab-webhook',
      status: 'firing',
      alerts: [{
        status: 'firing',
        labels: {
          alertname: 'IncidentLabDeliveryTest',
          instance: 'unit-test',
          service: 'incident-api',
          severity: 'warning'
        }
      }]
    })
  });
  assert.equal(notification.status, 202);
  assert.deepEqual(await notification.json(), { accepted: 1 });

  const receivedAlerts = await fetch(`${baseUrl}/api/alerts`);
  assert.equal(receivedAlerts.status, 200);
  const alertState = await receivedAlerts.json();
  assert.equal(alertState.batches, 1);
  assert.equal(alertState.alertsByStatus.firing, 1);
  assert.equal(alertState.lastAlertBatch.alerts[0].alertname, 'IncidentLabDeliveryTest');

  const metrics = await fetch(`${baseUrl}/metrics`);
  assert.equal(metrics.status, 200);
  const metricsBody = await metrics.text();
  assert.match(metricsBody, /incident_lab_orders_total/);
  assert.match(metricsBody, /incident_lab_alert_notifications_total\{service="incident-api",status="firing"\} 1/);
});

test('alert webhook rejects malformed payloads', async (t) => {
  const app = createApplication(loadConfig({ BACKEND_URL: 'http://dependency:8080' }));
  app.server.listen(0, '127.0.0.1');
  await once(app.server, 'listening');
  t.after(() => new Promise((resolve) => app.server.close(resolve)));

  const address = app.server.address();
  const response = await fetch(`http://127.0.0.1:${address.port}/api/alerts`, {
    method: 'POST',
    body: JSON.stringify({ status: 'firing' })
  });
  assert.equal(response.status, 400);
  assert.deepEqual(await response.json(), { error: 'alerts_array_required' });

  const oversized = await fetch(`http://127.0.0.1:${address.port}/api/alerts`, {
    method: 'POST',
    body: JSON.stringify({ alerts: [], padding: 'x'.repeat(70 * 1024) })
  });
  assert.equal(oversized.status, 413);
  assert.deepEqual(await oversized.json(), { error: 'request body exceeds 64 KiB' });
});
