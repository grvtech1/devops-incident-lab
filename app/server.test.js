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

test('health, order, and metrics endpoints form a valid smoke path', async (t) => {
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

  const metrics = await fetch(`${baseUrl}/metrics`);
  assert.equal(metrics.status, 200);
  assert.match(await metrics.text(), /incident_lab_orders_total/);
});
