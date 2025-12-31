# Contributing to Atlas Secure CI/CD Governance

This document outlines the development workflow, standards, and expectations for contributing to this repository.

---

## Development Workflow

### Branch Strategy

This repository uses **trunk-based development**:

```
main (protected)
  └── feature/description
  └── fix/description
  └── docs/description
```

- `main` is always deployable
- All changes go through pull requests
- Branch lifetime should be < 1 day when possible

### Branch Naming

```
<type>/<short-description>

Examples:
  feature/add-sbom-generation
  fix/trivy-cache-issue
  docs/update-architecture
```

Types: `feature`, `fix`, `docs`, `refactor`, `test`

---

## Commit Message Guidelines

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Examples

```
feat(pipeline): add SBOM generation stage

Integrates Syft for CycloneDX SBOM generation after container build.
SBOM is uploaded as artifact and attached to release.

Refs: #42
```

```
fix(trivy): update to v0.48 for CVE-2024-XXXX fix

Security update to address false negative in Trivy < 0.48
```

```
docs(adr): add decision record for Semgrep selection
```

### Type Reference

| Type | Description |
|------|-------------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change that neither fixes nor adds |
| `test` | Adding or updating tests |
| `chore` | Maintenance tasks |
| `security` | Security-related changes |

---

## Pull Request Expectations

### Before Opening PR

- [ ] All pipelines pass locally
- [ ] No secrets or credentials in code
- [ ] Documentation updated if needed
- [ ] ADR created for significant decisions

### PR Description Template

```markdown
## Summary
Brief description of what this PR does.

## Type of Change
- [ ] Feature
- [ ] Bug fix
- [ ] Documentation
- [ ] Refactor

## Security Considerations
Describe any security implications of this change.

## Testing
How was this tested?

## Checklist
- [ ] Pipelines pass
- [ ] No secrets in code
- [ ] Docs updated
```

### Review Process

1. Automated checks must pass
2. At least one approval required
3. Security-sensitive changes require security review
4. Squash merge preferred

---

## Code Style Expectations

### YAML (Workflows)

- 2-space indentation
- Explicit quotes for strings that could be interpreted as other types
- Comments for non-obvious steps

```yaml
# Good
name: Security Scan
on:
  pull_request:
    branches: ["main"]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
```

### Rego (Policies)

- One rule per concern
- Clear deny messages
- Unit tests for all policies

```rego
# Good - clear and testable
package container.security

deny[msg] {
    input.image.user == "root"
    msg := "Container must not run as root"
}
```

### Shell Scripts

- Use `set -euo pipefail`
- Quote all variables
- Include usage documentation

```bash
#!/bin/bash
set -euo pipefail

# Usage: ./scan.sh <image-name>
# Runs security scan on specified container image

IMAGE="${1:?Image name required}"
```

---

## Security & Confidentiality Rules

### Never Commit

- Secrets, tokens, or API keys
- Real vulnerability scan results
- Internal company configurations
- Production domain names or IPs
- Customer or user data

### Always Use

- Generic placeholder values (`example.com`)
- Synthetic test data
- Anonymized examples

### If Unsure

Ask before committing. When in doubt, leave it out.

---

## Testing & Validation

### Local Testing

Before pushing, run:

```bash
# Lint workflows
actionlint .github/workflows/*.yml

# Test Rego policies
opa test src/policies/ -v

# Validate examples
./scripts/validate-examples.sh
```

### CI Validation

All PRs automatically run:

- Workflow syntax validation
- Policy unit tests
- Example validation
- Documentation link checking

---

## Documentation Standards

### When to Update Docs

- Any new feature or capability
- Changed behavior
- New configuration options
- Architecture decisions (ADR)

### Documentation Locations

| Content | Location |
|---------|----------|
| High-level overview | `README.md` |
| Architecture details | `docs/architecture.md` |
| Decisions | `docs/adr/` |
| Security gates | `SECURITY_GATES.md` |
| Threat model | `THREAT_MODEL.md` |

---

## Architecture Decision Records (ADRs)

For significant decisions, create an ADR:

```
docs/adr/
  0001-choose-github-actions.md
  0002-trivy-over-alternatives.md
  0003-semgrep-for-sast.md
```

### ADR Template

```markdown
# ADR-XXXX: Title

## Status
Proposed | Accepted | Deprecated | Superseded

## Context
What is the issue we're addressing?

## Decision
What did we decide?

## Alternatives Considered
What else did we evaluate?

## Consequences
What are the implications?
```

---

## Questions?

Open an issue for:

- Clarification on standards
- Suggestions for improvement
- Security concerns
