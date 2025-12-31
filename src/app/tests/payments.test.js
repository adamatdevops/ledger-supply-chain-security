/**
 * Payments Routes Tests
 *
 * Tests for payments API endpoints.
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
const PORT = 3003;
const BASE_URL = `http://localhost:${PORT}`;
let createdPaymentId;

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
            body: data ? JSON.parse(data) : null
          });
        } catch {
          resolve({
            status: res.statusCode,
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

describe('Payments Routes', () => {
  before(() => {
    server = app.listen(PORT);
  });

  after(() => {
    server.close();
  });

  describe('POST /payments', () => {
    it('should create a new payment', async () => {
      const res = await request('/payments', {
        method: 'POST',
        body: {
          amount: 100.50,
          currency: 'USD',
          description: 'Test payment',
          recipient: 'test@example.com'
        }
      });

      assert.strictEqual(res.status, 201);
      assert.ok(res.body.id);
      assert.strictEqual(res.body.amount, 100.50);
      assert.strictEqual(res.body.currency, 'USD');
      assert.strictEqual(res.body.status, 'pending');

      createdPaymentId = res.body.id;
    });

    it('should reject invalid amount', async () => {
      const res = await request('/payments', {
        method: 'POST',
        body: {
          amount: -50,
          currency: 'USD',
          recipient: 'test@example.com'
        }
      });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.error, 'Invalid amount');
    });

    it('should reject missing currency', async () => {
      const res = await request('/payments', {
        method: 'POST',
        body: {
          amount: 100,
          recipient: 'test@example.com'
        }
      });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.error, 'Invalid currency');
    });

    it('should reject missing recipient', async () => {
      const res = await request('/payments', {
        method: 'POST',
        body: {
          amount: 100,
          currency: 'USD'
        }
      });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.error, 'Invalid recipient');
    });
  });

  describe('GET /payments', () => {
    it('should list all payments', async () => {
      const res = await request('/payments');

      assert.strictEqual(res.status, 200);
      assert.ok(Array.isArray(res.body.payments));
      assert.ok(res.body.count >= 1);
    });

    it('should filter by status', async () => {
      const res = await request('/payments?status=pending');

      assert.strictEqual(res.status, 200);
      assert.ok(res.body.payments.every(p => p.status === 'pending'));
    });

    it('should respect limit parameter', async () => {
      const res = await request('/payments?limit=1');

      assert.strictEqual(res.status, 200);
      assert.ok(res.body.payments.length <= 1);
    });
  });

  describe('GET /payments/:id', () => {
    it('should return a specific payment', async () => {
      const res = await request(`/payments/${createdPaymentId}`);

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.id, createdPaymentId);
    });

    it('should return 404 for non-existent payment', async () => {
      const res = await request('/payments/non-existent-id');

      assert.strictEqual(res.status, 404);
      assert.strictEqual(res.body.error, 'Payment not found');
    });
  });

  describe('PATCH /payments/:id/status', () => {
    it('should update payment status', async () => {
      const res = await request(`/payments/${createdPaymentId}/status`, {
        method: 'PATCH',
        body: { status: 'processing' }
      });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.status, 'processing');
    });

    it('should reject invalid status', async () => {
      const res = await request(`/payments/${createdPaymentId}/status`, {
        method: 'PATCH',
        body: { status: 'invalid' }
      });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.error, 'Invalid status');
    });

    it('should return 404 for non-existent payment', async () => {
      const res = await request('/payments/non-existent-id/status', {
        method: 'PATCH',
        body: { status: 'completed' }
      });

      assert.strictEqual(res.status, 404);
    });
  });

  describe('DELETE /payments/:id', () => {
    it('should delete a payment', async () => {
      // Create a new payment to delete
      const createRes = await request('/payments', {
        method: 'POST',
        body: {
          amount: 50,
          currency: 'EUR',
          recipient: 'delete@example.com'
        }
      });

      const res = await request(`/payments/${createRes.body.id}`, {
        method: 'DELETE'
      });

      assert.strictEqual(res.status, 204);
    });

    it('should return 404 for non-existent payment', async () => {
      const res = await request('/payments/non-existent-id', {
        method: 'DELETE'
      });

      assert.strictEqual(res.status, 404);
    });

    it('should not delete completed payment', async () => {
      // Mark payment as completed
      await request(`/payments/${createdPaymentId}/status`, {
        method: 'PATCH',
        body: { status: 'completed' }
      });

      const res = await request(`/payments/${createdPaymentId}`, {
        method: 'DELETE'
      });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.error, 'Cannot delete completed payment');
    });
  });
});
