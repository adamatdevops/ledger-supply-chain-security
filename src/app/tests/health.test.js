/**
 * Health Routes Tests
 *
 * Tests for liveness and readiness probe endpoints.
 * Uses Node.js built-in test runner (Node 20+).
 *
 * Run: npm test
 */

const { describe, it, before, after } = require('node:test');
const assert = require('node:assert');
const http = require('node:http');

// Set test environment before requiring app
process.env.NODE_ENV = 'test';
const app = require('../server');

let server;
const PORT = 3001;
const BASE_URL = `http://localhost:${PORT}`;

/**
 * Helper to make HTTP requests
 */
function request(path, options = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const req = http.request(url, {
      method: options.method || 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...options.headers
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({
            status: res.statusCode,
            headers: res.headers,
            body: data ? JSON.parse(data) : null
          });
        } catch {
          resolve({
            status: res.statusCode,
            headers: res.headers,
            body: data
          });
        }
      });
    });

    req.on('error', reject);

    if (options.body) {
      req.write(JSON.stringify(options.body));
    }

    req.end();
  });
}

describe('Health Routes', () => {
  before(() => {
    server = app.listen(PORT);
  });

  after(() => {
    server.close();
  });

  describe('GET /health', () => {
    it('should return healthy status', async () => {
      const res = await request('/health');

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.status, 'healthy');
      assert.ok(res.body.timestamp);
      assert.ok(typeof res.body.uptime === 'number');
    });
  });

  describe('GET /health/live', () => {
    it('should return alive status', async () => {
      const res = await request('/health/live');

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.status, 'alive');
      assert.ok(res.body.timestamp);
    });
  });

  describe('GET /health/ready', () => {
    it('should return ready status by default', async () => {
      const res = await request('/health/ready');

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.status, 'ready');
    });
  });

  describe('POST /health/ready', () => {
    it('should set readiness to false', async () => {
      const res = await request('/health/ready', {
        method: 'POST',
        body: { ready: false }
      });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.status, 'not ready');
    });

    it('should return 503 when not ready', async () => {
      const res = await request('/health/ready');

      assert.strictEqual(res.status, 503);
      assert.strictEqual(res.body.status, 'not ready');
    });

    it('should set readiness back to true', async () => {
      const res = await request('/health/ready', {
        method: 'POST',
        body: { ready: true }
      });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.status, 'ready');
    });

    it('should reject invalid body', async () => {
      const res = await request('/health/ready', {
        method: 'POST',
        body: { ready: 'invalid' }
      });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.error, 'Invalid request');
    });
  });
});
