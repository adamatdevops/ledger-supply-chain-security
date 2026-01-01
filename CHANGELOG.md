# Changelog

All notable changes to the Ledger Supply Chain Security project are documented in this file.

## [1.0.0] - 2025-01-01

### Project Milestone: Both Pipelines Green

Successfully completed development of a comprehensive DevSecOps portfolio repository demonstrating:
- **Supply Chain Security Pipeline** - SBOM, signing, attestation, and policy-as-code
- **Multi-Language Security Scan** - Universal security scanning for 9+ languages/frameworks

---

## Development History

### Phase 5: Pipeline Stabilization

#### fix: Deploy jobs missing build dependency (090a181)
**Workflow:** Supply Chain Security Pipeline
- Added `build` to `needs` array for all deploy jobs
- Fixed `needs.build.outputs.image-digest` access (was undefined)
- Added conditions to check `build.result == 'success'`
- Prevents empty digest errors when build is skipped

#### fix: ECR registry approval rule (f14db8a)
**Workflow:** Both (OPA Policies)
- Changed ECR check from `endswith()` to `contains()`
- Allows matching full ECR image references with tags
- All 63 OPA policy tests now passing

#### fix: Docker build path and OPA v0.46+ syntax (aeffd14)
**Workflow:** Supply Chain Security Pipeline
- Updated Docker build context to `src/app`
- Added explicit `file: src/app/Dockerfile`
- Migrated all Rego policies to OPA v0.46+ syntax:
  - Added `import rego.v1` header
  - Updated rule syntax with `if` keyword
  - Changed partial sets to `contains` syntax
  - Fixed iteration patterns

---

### Phase 4: Hybrid Enforcement Mode

#### feat: Add hybrid enforcement mode (a98080a)
**Workflow:** Both Pipelines
- Added `ENFORCE_SECURITY` environment variable
- `'false'` = report-only (observability mode)
- `'true'` = blocking (enforcement mode)
- Added `continue-on-error` with conditional expression
- Added `if: always()` to downstream jobs
- Enables gradual security maturity adoption

---

### Phase 3: Multi-Language Support

#### fix: Resolve multi-language scan failures (5a87b86)
**Workflow:** Multi-Language Security Scan
- Fixed Dockerfile detection with dynamic path finding
- Fixed Node.js dependency installation across multiple directories
- Added proper working directory handling for pnpm

#### feat: Add Pulumi TypeScript infrastructure (5f519d9)
**Workflow:** Multi-Language Security Scan
- Added `pulumi/` directory with AWS EKS infrastructure
- TypeScript-based Pulumi program
- Added Pulumi detection in language scanner

#### feat: Add Python, Go, and Terraform services (0627afa)
**Workflow:** Multi-Language Security Scan
- Added `src/python-service/` - Audit Service (Flask)
- Added `src/go-service/` - Notification Service
- Added `terraform/` - AWS EKS Infrastructure
- All services include proper security configurations

#### fix: Use recursive search for language detection (7bc5c8e)
**Workflow:** Multi-Language Security Scan
- Changed from root-only to recursive file detection
- Now finds package.json, requirements.txt, go.mod, etc. in subdirectories
- Properly detects all 9 language/framework types

---

### Phase 2: Security Scanner Configuration

#### fix: Update .semgrepignore syntax (b00166c)
**Workflow:** Both Pipelines
- Added multiple glob patterns for `examples/invalid/`
- Excludes intentionally insecure test fixtures from SAST

#### fix: Exclude examples/invalid from SAST (d976294)
**Workflow:** Both Pipelines
- Created `.semgrepignore` file
- Prevents false positives from intentional security violations

#### fix: Use SNYK_SCAN_TOKEN secret name (c2ffb5b)
**Workflow:** Both Pipelines
- Updated all Snyk actions to use correct secret name
- Matches user's GitHub repository secret configuration

---

### Phase 1: Initial Setup

#### feat: Add workflow_dispatch (d19c180)
**Workflow:** Both Pipelines
- Enabled manual triggering from GitHub Actions UI
- Added severity threshold input for Multi-Language scan

#### chore: Add AI config to gitignore (fe9b0ba)
**Workflow:** N/A (Repository)
- Added PROMPT.md and CONTEXT.md to .gitignore
- Fixed Trivy references to Snyk throughout codebase

#### feat: Initial commit (2f4c67a)
**Workflow:** Both Pipelines
- Complete supply chain security pipeline
- Multi-language security scanning workflow
- OPA/Rego policy-as-code framework
- Example valid/invalid manifests for testing
- Comprehensive documentation

---

## Workflows Summary

### Supply Chain Security Pipeline (`secure-pipeline.yml`)
| Stage | Tools | Purpose |
|-------|-------|---------|
| Code Quality | ESLint, Prettier, Jest | Fast feedback on code hygiene |
| Security Scan | Gitleaks, Semgrep, Snyk | SAST, secrets, dependencies |
| Build & Package | Docker, Buildx | Container image with caching |
| Container Security | Snyk, Syft, Cosign | Scan, SBOM, sign, attest |
| Policy Check | OPA, Conftest | Policy-as-code validation |
| Deploy Gates | GitHub Environments | Dev → Staging → Production |

### Multi-Language Security Scan (`multi-language-security.yml`)
| Language | Tools | Coverage |
|----------|-------|----------|
| Node.js | pnpm audit, Snyk, Semgrep | npm/yarn/pnpm projects |
| Python | Safety, Bandit, Snyk | pip/pipenv/poetry |
| Go | govulncheck, gosec, Snyk | Go modules |
| Java | OWASP DC, Snyk | Maven/Gradle |
| Ruby | bundler-audit, Brakeman | Bundler/Rails |
| .NET | Snyk | NuGet packages |
| Docker | Hadolint, Snyk, Dockle | Container security |
| Terraform | tfsec, Checkov, Snyk | IaC security |
| Pulumi | Snyk, Checkov | TypeScript IaC |

---

## Configuration

### Environment Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `ENFORCE_SECURITY` | `'false'` | Set to `'true'` to block on findings |
| `SEVERITY_THRESHOLD` | `'high'` | Minimum severity to report |

### Required Secrets
| Secret | Purpose |
|--------|---------|
| `SNYK_SCAN_TOKEN` | Snyk API authentication |
| `GITHUB_TOKEN` | Automatically provided |

---

## License

MIT License - See [LICENSE](LICENSE) for details.
