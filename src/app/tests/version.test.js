/**
 * Version Routes Tests
 *
 * Tests for version and build info endpoints.
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
const PORT = 3002;
const BASE_URL = `http://localhost:${PORT}`;

/**
 * Helper to make HTTP requests
 */
function request(path) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    http.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({
            status: res.statusCode,
            body: JSON.parse(data)
          });
        } catch {
          resolve({
            status: res.statusCode,
            body: data
          });
        }
      });
    }).on('error', reject);
  });
}

describe('Version Routes', () => {
  before(() => {
    server = app.listen(PORT);
  });

  after(() => {
    server.close();
  });

  describe('GET /version', () => {
    it('should return version info', async () => {
      const res = await request('/version');

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.name, 'payments-api');
      assert.strictEqual(res.body.version, '1.0.0');
      assert.ok(res.body.commit);
      assert.ok(res.body.branch);
    });
  });

  describe('GET /version/short', () => {
    it('should return just the version string', async () => {
      const res = await request('/version/short');

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body, '1.0.0');
    });
  });

  describe('GET /version/commit', () => {
    it('should return the commit hash', async () => {
      const res = await request('/version/commit');

      assert.strictEqual(res.status, 200);
      assert.ok(typeof res.body === 'string');
    });
  });
});
