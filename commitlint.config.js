// =============================================================================
// Commitlint Configuration
// =============================================================================
// Enforces conventional commit message format.
// Used by pre-commit hook and CI validation.
//
// Format: <type>(<scope>): <subject>
// Example: feat(pipeline): add SBOM generation stage
//
// Documentation: https://commitlint.js.org
// =============================================================================

module.exports = {
  extends: ['@commitlint/config-conventional'],

  // Custom rules
  rules: {
    // Type must be one of the following
    'type-enum': [
      2,
      'always',
      [
        'feat',     // New feature
        'fix',      // Bug fix
        'docs',     // Documentation only
        'style',    // Formatting, no code change
        'refactor', // Code change, no feature/fix
        'perf',     // Performance improvement
        'test',     // Adding/updating tests
        'build',    // Build system or dependencies
        'ci',       // CI/CD configuration
        'chore',    // Maintenance tasks
        'revert',   // Revert previous commit
        'security', // Security-related changes
      ],
    ],

    // Type must be lowercase
    'type-case': [2, 'always', 'lower-case'],

    // Type cannot be empty
    'type-empty': [2, 'never'],

    // Scope must be lowercase
    'scope-case': [2, 'always', 'lower-case'],

    // Subject cannot be empty
    'subject-empty': [2, 'never'],

    // Subject must start with lowercase
    'subject-case': [2, 'always', 'lower-case'],

    // Subject cannot end with period
    'subject-full-stop': [2, 'never', '.'],

    // Header max length (type + scope + subject)
    'header-max-length': [2, 'always', 100],

    // Body max line length
    'body-max-line-length': [2, 'always', 200],

    // Footer max line length
    'footer-max-line-length': [2, 'always', 200],
  },

  // Scopes relevant to this repository
  // Uncomment and customize as needed
  // 'scope-enum': [
  //   2,
  //   'always',
  //   [
  //     'pipeline',
  //     'policy',
  //     'security',
  //     'docs',
  //     'deps',
  //     'container',
  //     'ci',
  //   ],
  // ],

  // Help message shown on commit failure
  helpUrl: 'https://www.conventionalcommits.org/',
};
