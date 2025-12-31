/**
 * Payments Routes
 *
 * Mock payments API demonstrating Fintech-style endpoints.
 * In-memory storage for demonstration purposes.
 */

const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');

// In-memory payment storage (demo only)
const payments = new Map();

/**
 * GET /payments
 * List all payments
 */
router.get('/', (req, res) => {
  const { status, limit = 10 } = req.query;

  let results = Array.from(payments.values());

  if (status) {
    results = results.filter(p => p.status === status);
  }

  results = results.slice(0, parseInt(limit, 10));

  res.json({
    count: results.length,
    payments: results
  });
});

/**
 * GET /payments/:id
 * Get a specific payment
 */
router.get('/:id', (req, res) => {
  const payment = payments.get(req.params.id);

  if (!payment) {
    return res.status(404).json({
      error: 'Payment not found',
      id: req.params.id
    });
  }

  res.json(payment);
});

/**
 * POST /payments
 * Create a new payment
 */
router.post('/', (req, res) => {
  const { amount, currency, description, recipient } = req.body;

  // Basic validation
  if (!amount || typeof amount !== 'number' || amount <= 0) {
    return res.status(400).json({
      error: 'Invalid amount',
      message: 'Amount must be a positive number'
    });
  }

  if (!currency || typeof currency !== 'string') {
    return res.status(400).json({
      error: 'Invalid currency',
      message: 'Currency is required'
    });
  }

  if (!recipient || typeof recipient !== 'string') {
    return res.status(400).json({
      error: 'Invalid recipient',
      message: 'Recipient is required'
    });
  }

  const payment = {
    id: uuidv4(),
    amount,
    currency: currency.toUpperCase(),
    description: description || '',
    recipient,
    status: 'pending',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };

  payments.set(payment.id, payment);

  res.status(201).json(payment);
});

/**
 * PATCH /payments/:id/status
 * Update payment status
 */
router.patch('/:id/status', (req, res) => {
  const { status } = req.body;
  const validStatuses = ['pending', 'processing', 'completed', 'failed', 'cancelled'];

  if (!validStatuses.includes(status)) {
    return res.status(400).json({
      error: 'Invalid status',
      message: `Status must be one of: ${validStatuses.join(', ')}`
    });
  }

  const payment = payments.get(req.params.id);

  if (!payment) {
    return res.status(404).json({
      error: 'Payment not found',
      id: req.params.id
    });
  }

  payment.status = status;
  payment.updatedAt = new Date().toISOString();

  res.json(payment);
});

/**
 * DELETE /payments/:id
 * Cancel/delete a payment
 */
router.delete('/:id', (req, res) => {
  const payment = payments.get(req.params.id);

  if (!payment) {
    return res.status(404).json({
      error: 'Payment not found',
      id: req.params.id
    });
  }

  if (payment.status === 'completed') {
    return res.status(400).json({
      error: 'Cannot delete completed payment',
      id: req.params.id
    });
  }

  payments.delete(req.params.id);

  res.status(204).send();
});

module.exports = router;
