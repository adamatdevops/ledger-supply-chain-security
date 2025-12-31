/**
 * Version Routes
 *
 * Provides version and build information.
 * Useful for deployment verification and debugging.
 */

const express = require('express');
const router = express.Router();
const pkg = require('../package.json');

// Build info from environment (set during CI/CD)
const buildInfo = {
  version: pkg.version,
  name: pkg.name,
  commit: process.env.GIT_COMMIT || 'unknown',
  branch: process.env.GIT_BRANCH || 'unknown',
  buildTime: process.env.BUILD_TIME || 'unknown',
  buildNumber: process.env.BUILD_NUMBER || 'unknown'
};

/**
 * GET /version
 * Returns version and build information
 */
router.get('/', (req, res) => {
  res.json(buildInfo);
});

/**
 * GET /version/short
 * Returns just the version string
 */
router.get('/short', (req, res) => {
  res.send(buildInfo.version);
});

/**
 * GET /version/commit
 * Returns the git commit hash
 */
router.get('/commit', (req, res) => {
  res.send(buildInfo.commit);
});

module.exports = router;
