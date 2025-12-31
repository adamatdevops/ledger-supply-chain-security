/**
 * Health Check Routes
 *
 * Provides liveness and readiness endpoints for Kubernetes probes.
 */

const express = require('express');
const router = express.Router();

// Track readiness state
let isReady = true;

/**
 * GET /health
 * Liveness probe - is the service alive?
 */
router.get('/', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

/**
 * GET /health/live
 * Explicit liveness endpoint
 */
router.get('/live', (req, res) => {
  res.json({
    status: 'alive',
    timestamp: new Date().toISOString()
  });
});

/**
 * GET /health/ready
 * Readiness probe - is the service ready to accept traffic?
 */
router.get('/ready', (req, res) => {
  if (isReady) {
    res.json({
      status: 'ready',
      timestamp: new Date().toISOString()
    });
  } else {
    res.status(503).json({
      status: 'not ready',
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * POST /health/ready
 * Toggle readiness state (for testing)
 */
router.post('/ready', (req, res) => {
  const { ready } = req.body;
  if (typeof ready === 'boolean') {
    isReady = ready;
    res.json({
      status: isReady ? 'ready' : 'not ready',
      message: `Readiness set to ${isReady}`
    });
  } else {
    res.status(400).json({
      error: 'Invalid request',
      message: 'Body must contain { ready: boolean }'
    });
  }
});

module.exports = router;
