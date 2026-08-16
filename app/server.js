'use strict';

const http = require('node:http');
const { randomUUID } = require('node:crypto');

const retainedBuffers = [];

function numberFromEnv(value, fallback, name) {
  if (value === undefined || value === '') return fallback;
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < 0) {
    throw new Error(`${name} must be a non-negative number`);
  }
  return parsed;
}

function loadConfig(env = process.env) {
  const config = {
    port: numberFromEnv(env.PORT, 8080, 'PORT'),
    serviceName: env.SERVICE_NAME || 'incident-api',
    appEnv: env.APP_ENV || 'development',
    backendUrl: env.BACKEND_URL || '',
    failureRate: numberFromEnv(env.FAILURE_RATE, 0, 'FAILURE_RATE'),
    startupDelayMs: numberFromEnv(env.STARTUP_DELAY_MS, 0, 'STARTUP_DELAY_MS'),
    shutdownDelayMs: numberFromEnv(env.SHUTDOWN_DELAY_MS, 3000, 'SHUTDOWN_DELAY_MS'),
    allocateOnStartMb: numberFromEnv(env.ALLOCATE_ON_START_MB, 0, 'ALLOCATE_ON_START_MB'),
    chaosEnabled: env.CHAOS_ENABLED === 'true'
  };

  if (config.failureRate > 1) throw new Error('FAILURE_RATE must be between 0 and 1');
  if (!config.backendUrl) throw new Error('BACKEND_URL is required');
  try {
    new URL(config.backendUrl);
  } catch {
    throw new Error(`BACKEND_URL is invalid: ${config.backendUrl}`);
  }
  return config;
}

function log(level, message, fields = {}) {
  process.stdout.write(`${JSON.stringify({
    timestamp: new Date().toISOString(),
    level,
    message,
    ...fields
  })}\n`);
}

function createApplication(config) {
  const startedAt = Date.now();
  const counters = {
    requests: new Map(),
    errors: 0,
    orders: 0
  };
  let ready = false;
  let shuttingDown = false;

  const readinessTimer = setTimeout(() => {
    ready = true;
    log('info', 'application_ready', { service: config.serviceName });
  }, config.startupDelayMs);

  if (config.allocateOnStartMb > 0) {
    setTimeout(() => {
      const bytes = Math.floor(config.allocateOnStartMb * 1024 * 1024);
      retainedBuffers.push(Buffer.alloc(bytes, 1));
      log('warn', 'startup_memory_allocated', { megabytes: config.allocateOnStartMb });
    }, Math.max(config.startupDelayMs, 100));
  }

  function increment(method, route, status) {
    const key = `${method}|${route}|${status}`;
    counters.requests.set(key, (counters.requests.get(key) || 0) + 1);
    if (status >= 500) counters.errors += 1;
  }

  function sendJson(res, status, body, method = 'GET', route = 'unknown') {
    increment(method, route, status);
    const payload = JSON.stringify(body);
    res.writeHead(status, {
      'content-type': 'application/json; charset=utf-8',
      'content-length': Buffer.byteLength(payload),
      'x-service-name': config.serviceName
    });
    res.end(payload);
  }

  function metrics() {
    const lines = [
      '# HELP incident_lab_http_requests_total HTTP requests handled by the lab service.',
      '# TYPE incident_lab_http_requests_total counter'
    ];
    for (const [key, value] of counters.requests.entries()) {
      const [method, route, status] = key.split('|');
      lines.push(`incident_lab_http_requests_total{method="${method}",route="${route}",status="${status}",service="${config.serviceName}"} ${value}`);
    }
    lines.push('# HELP incident_lab_http_errors_total HTTP 5xx responses.');
    lines.push('# TYPE incident_lab_http_errors_total counter');
    lines.push(`incident_lab_http_errors_total{service="${config.serviceName}"} ${counters.errors}`);
    lines.push('# HELP incident_lab_orders_total Orders accepted by the sample API.');
    lines.push('# TYPE incident_lab_orders_total counter');
    lines.push(`incident_lab_orders_total{service="${config.serviceName}"} ${counters.orders}`);
    lines.push('# HELP process_resident_memory_bytes Resident memory reported by Node.js.');
    lines.push('# TYPE process_resident_memory_bytes gauge');
    lines.push(`process_resident_memory_bytes ${process.memoryUsage().rss}`);
    lines.push('# HELP incident_lab_uptime_seconds Process uptime in seconds.');
    lines.push('# TYPE incident_lab_uptime_seconds gauge');
    lines.push(`incident_lab_uptime_seconds ${Math.floor((Date.now() - startedAt) / 1000)}`);
    return `${lines.join('\n')}\n`;
  }

  const server = http.createServer((req, res) => {
    const requestId = req.headers['x-request-id'] || randomUUID();
    const url = new URL(req.url, 'http://localhost');
    const route = url.pathname;
    const requestStartedAt = process.hrtime.bigint();

    res.setHeader('x-request-id', requestId);
    log('info', 'request_started', { requestId, method: req.method, route });
    res.once('finish', () => {
      const durationMs = Number(process.hrtime.bigint() - requestStartedAt) / 1e6;
      log('info', 'request_completed', {
        requestId,
        method: req.method,
        route,
        statusCode: res.statusCode,
        durationMs: Number(durationMs.toFixed(2))
      });
    });

    if (route === '/health/live') {
      return sendJson(res, shuttingDown ? 503 : 200, { status: shuttingDown ? 'stopping' : 'alive' }, req.method, route);
    }
    if (route === '/health/ready') {
      return sendJson(res, ready && !shuttingDown ? 200 : 503, { status: ready && !shuttingDown ? 'ready' : 'not-ready' }, req.method, route);
    }
    if (route === '/metrics') {
      const payload = metrics();
      increment(req.method, route, 200);
      res.writeHead(200, { 'content-type': 'text/plain; version=0.0.4; charset=utf-8' });
      return res.end(payload);
    }
    if (route === '/api/orders' && req.method === 'POST') {
      if (Math.random() < config.failureRate) {
        return sendJson(res, 500, { error: 'simulated_order_failure', requestId }, req.method, route);
      }
      counters.orders += 1;
      return sendJson(res, 202, {
        orderId: `ord-${String(counters.orders).padStart(5, '0')}`,
        status: 'accepted',
        requestId
      }, req.method, route);
    }
    if (route === '/api/config') {
      return sendJson(res, 200, {
        service: config.serviceName,
        environment: config.appEnv,
        backendHost: new URL(config.backendUrl).host,
        failureRate: config.failureRate
      }, req.method, route);
    }
    if (route === '/chaos/memory' && req.method === 'POST') {
      if (!config.chaosEnabled) {
        return sendJson(res, 403, { error: 'chaos_disabled' }, req.method, route);
      }
      const megabytes = numberFromEnv(url.searchParams.get('mb'), 64, 'mb');
      retainedBuffers.push(Buffer.alloc(Math.floor(megabytes * 1024 * 1024), 1));
      return sendJson(res, 200, { allocatedMb: megabytes, retainedAllocations: retainedBuffers.length }, req.method, route);
    }
    if (route === '/chaos/cpu') {
      if (!config.chaosEnabled) {
        return sendJson(res, 403, { error: 'chaos_disabled' }, req.method, route);
      }
      const milliseconds = Math.min(numberFromEnv(url.searchParams.get('ms'), 500, 'ms'), 10000);
      const until = Date.now() + milliseconds;
      while (Date.now() < until) Math.sqrt(Math.random());
      return sendJson(res, 200, { busyMs: milliseconds }, req.method, route);
    }
    if (route === '/') {
      return sendJson(res, 200, {
        service: config.serviceName,
        message: 'DevOps Incident Lab is running',
        endpoints: ['/health/live', '/health/ready', '/api/orders', '/metrics']
      }, req.method, route);
    }
    return sendJson(res, 404, { error: 'not_found', requestId }, req.method, route);
  });

  function shutdown(signal) {
    if (shuttingDown) return;
    shuttingDown = true;
    ready = false;
    clearTimeout(readinessTimer);
    log('info', 'shutdown_started', { signal, delayMs: config.shutdownDelayMs });
    setTimeout(() => {
      server.close(() => {
        log('info', 'shutdown_complete', { signal });
        process.exitCode = 0;
      });
    }, config.shutdownDelayMs);
  }

  return { server, shutdown };
}

function main() {
  let config;
  try {
    config = loadConfig();
  } catch (error) {
    log('error', 'startup_validation_failed', { error: error.message });
    process.exitCode = 1;
    return;
  }

  const app = createApplication(config);
  app.server.listen(config.port, '0.0.0.0', () => {
    log('info', 'server_listening', {
      service: config.serviceName,
      environment: config.appEnv,
      port: config.port
    });
  });
  process.on('SIGTERM', () => app.shutdown('SIGTERM'));
  process.on('SIGINT', () => app.shutdown('SIGINT'));
}

if (require.main === module) main();

module.exports = { createApplication, loadConfig };
