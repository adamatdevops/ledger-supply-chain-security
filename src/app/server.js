/**
 * Payments API Server
 *
 * Minimal Fintech API demonstrating secure CI/CD pipeline.
 * This service provides health, version, and payments endpoints.
 */

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');

const healthRoutes = require('./routes/health');
const versionRoutes = require('./routes/version');
const paymentsRoutes = require('./routes/payments');

const app = express();
const PORT = process.env.PORT || 8080;

// Security middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Request logging (simple)
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`${req.method} ${req.path} ${res.statusCode} ${duration}ms`);
  });
  next();
});

// Routes
app.use('/health', healthRoutes);
app.use('/version', versionRoutes);
app.use('/payments', paymentsRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    service: 'payments-api',
    status: 'running',
    docs: '/health, /version, /payments'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    path: req.path
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err.message);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'production' ? 'Something went wrong' : err.message
  });
});

// Start server (only if not in test mode)
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`Payments API listening on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  });
}

module.exports = app;
