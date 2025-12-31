# Detailed Architecture — Atlas Secure CI/CD Governance

## Overview

Atlas is a security-first CI/CD pipeline architecture implementing defense-in-depth through multiple scanning stages, policy gates, and artifact signing.

---

## System Components

### 1. Pre-Commit Layer

**Purpose**: Catch issues before code leaves developer machine.

```
Developer Machine
├── .pre-commit-config.yaml
├── Gitleaks (secret detection)
├── Linters (code quality)
└── Local test runner
```

**Note**: This layer is advisory only. Developers can bypass, so server-side validation is authoritative.

---

### 2. PR Validation Layer

**Purpose**: Gate for code entering shared branches.

```yaml
Trigger: Pull Request to main/develop

Jobs:
  code-quality:
    - checkout
    - lint
    - format-check
    - unit-tests

  security-scan:
    - checkout
    - sast-scan (Semgrep)
    - secret-scan (Gitleaks)
    - dependency-scan (Trivy)
    - license-scan (Trivy)

  results:
    - aggregate findings
    - post PR comments
    - update status checks
```

**Blocking Logic**:
```
IF secret_detected THEN block
IF sast_critical > 0 THEN block
IF cve_critical > 0 AND environment != dev THEN block
ELSE pass
```

---

### 3. Build Layer

**Purpose**: Create and secure artifacts.

```yaml
Trigger: Merge to main

Jobs:
  build:
    - checkout
    - build application
    - run integration tests

  package:
    - docker build (multi-stage)
    - generate SBOM (Syft)
    - sign image (Cosign)
    - push to registry
```

**Dockerfile Best Practices Enforced**:
```dockerfile
# Multi-stage build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM gcr.io/distroless/nodejs20
COPY --from=builder /app /app
USER nonroot
HEALTHCHECK --interval=30s CMD ["/app/healthcheck.js"]
```

---

### 4. Post-Build Verification Layer

**Purpose**: Validate artifacts before deployment eligibility.

```yaml
Jobs:
  container-scan:
    - pull built image
    - trivy image scan
    - check against policy

  verify:
    - verify image signature
    - validate SBOM exists
    - run policy checks (OPA)
```

**Container Policy Example**:
```rego
package container.security

default allow = false

allow {
    no_critical_vulns
    no_root_user
    has_healthcheck
    image_signed
}

no_critical_vulns {
    input.vulnerabilities.critical == 0
}

no_root_user {
    input.config.user != "root"
    input.config.user != ""
}

has_healthcheck {
    input.config.healthcheck != null
}

image_signed {
    input.signature.verified == true
}
```

---

### 5. Deployment Gate Layer

**Purpose**: Final check before environment promotion.

```yaml
Trigger: Deployment request

Jobs:
  gate:
    - verify artifact provenance
    - check environment policies
    - validate required approvals
    - deploy or block

Environments:
  dev:
    - auto-deploy on gate pass
  staging:
    - auto-deploy on gate pass
  prod:
    - require manual approval
    - deploy on approval + gate pass
```

---

## Data Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│                           DEVELOPER                                  │
└──────────────────────────────────────────────────────────────────────┘
         │
         │ git push
         ▼
┌──────────────────────────────────────────────────────────────────────┐
│                         GITHUB REPOSITORY                            │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ Branch Protection: Require PR, status checks, reviews          │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
         │
         │ webhook
         ▼
┌──────────────────────────────────────────────────────────────────────┐
│                        GITHUB ACTIONS                                │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐    │
│  │ Code       │  │ Security   │  │ Build      │  │ Post-Build │    │
│  │ Quality    │  │ Scan       │  │ Package    │  │ Verify     │    │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘    │
└──────────────────────────────────────────────────────────────────────┘
         │
         │ push artifact
         ▼
┌──────────────────────────────────────────────────────────────────────┐
│                       CONTAINER REGISTRY                             │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ Signed images, SBOM attestations, vulnerability metadata        │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
         │
         │ deploy request
         ▼
┌──────────────────────────────────────────────────────────────────────┐
│                        DEPLOYMENT GATE                               │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ Policy validation, signature verification, approval check       │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
         │
         │ deploy (if pass)
         ▼
┌──────────────────────────────────────────────────────────────────────┐
│                         KUBERNETES                                   │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐                       │
│  │   DEV    │    │ STAGING  │    │   PROD   │                       │
│  └──────────┘    └──────────┘    └──────────┘                       │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Tool Integration Details

### Semgrep (SAST)

**Purpose**: Static Application Security Testing

**Configuration**:
```yaml
# .semgrep.yml
rules:
  - id: custom-sql-injection
    pattern: |
      cursor.execute($QUERY)
    message: "Potential SQL injection"
    severity: ERROR
    languages: [python]
```

**Rulesets Used**:
- `p/security-audit` — General security rules
- `p/owasp-top-ten` — OWASP coverage
- `p/secrets` — Hardcoded credentials
- Custom rules for organization-specific patterns

---

### Gitleaks (Secret Detection)

**Purpose**: Prevent credential leaks

**Configuration**:
```toml
# .gitleaks.toml
[extend]
useDefault = true

[[rules]]
id = "internal-api-key"
description = "Internal API Key Pattern"
regex = '''INTERNAL_[A-Z]+_KEY\s*=\s*['"][a-zA-Z0-9]{32,}'''
secretGroup = 0
```

**Allowlist**:
```toml
[allowlist]
paths = [
    '''tests/fixtures/.*''',
    '''docs/examples/.*'''
]
```

---

### Snyk (Vulnerability Scanner)

**Purpose**: Vulnerability scanning with actionable remediation

**Modes Used**:

1. **Dependency Scan** (Open Source):
```bash
snyk test --severity-threshold=high
```

2. **Container Scan**:
```bash
snyk container test myapp:latest --file=Dockerfile
```

3. **IaC Scan**:
```bash
snyk iac test ./terraform
```

4. **Code Scan** (SAST):
```bash
snyk code test
```

5. **Continuous Monitoring**:
```bash
snyk monitor  # Track for new vulnerabilities
```

**Key Features**:
- Fix recommendations with upgrade paths
- Automated fix PRs
- License compliance checking
- Priority scoring based on exploitability
- SARIF output for GitHub Security integration

---

### Syft (SBOM Generation)

**Purpose**: Create Software Bill of Materials

**Output Format**: CycloneDX 1.5 JSON

```bash
syft myapp:latest -o cyclonedx-json > sbom.json
```

**SBOM Contains**:
- All packages with versions
- Package sources
- Licenses
- Dependency relationships

---

### Cosign (Image Signing)

**Purpose**: Cryptographic artifact integrity

**Keyless Signing** (recommended):
```bash
cosign sign --yes ghcr.io/org/myapp:latest
```

**Verification**:
```bash
cosign verify ghcr.io/org/myapp:latest \
  --certificate-identity-regexp='.*' \
  --certificate-oidc-issuer='https://token.actions.githubusercontent.com'
```

**Attestation** (attach SBOM):
```bash
cosign attest --predicate sbom.json ghcr.io/org/myapp:latest
```

---

### OPA/Conftest (Policy Validation)

**Purpose**: Enforce organizational policies

**Example Policies**:

```rego
# policies/deployment.rego
package kubernetes.deployment

deny[msg] {
    input.kind == "Deployment"
    not input.spec.template.spec.securityContext.runAsNonRoot
    msg := "Deployments must run as non-root"
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    container.securityContext.privileged
    msg := sprintf("Container %s must not be privileged", [container.name])
}
```

**Enforcement**:
```bash
conftest test deployment.yaml -p policies/
```

---

## Caching Strategy

To optimize pipeline performance:

| Cache | Content | TTL |
|-------|---------|-----|
| Dependency cache | npm/pip/go modules | 7 days |
| Trivy DB | Vulnerability database | 24 hours |
| Semgrep rules | Rule definitions | 24 hours |
| Docker layers | Build layers | Per branch |

**GitHub Actions Cache Example**:
```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.cache/trivy
      ~/.semgrep/cache
    key: security-tools-${{ runner.os }}-${{ hashFiles('.tool-versions') }}
```

---

## Error Handling

### Fail-Fast Behavior

```yaml
# Default: Fail immediately on security issue
fail_on_error: true

# Environment override for dev
env:
  dev:
    fail_on_error: false
    report_only: true
```

### Timeout Handling

```yaml
jobs:
  security-scan:
    timeout-minutes: 30
    steps:
      - name: SAST Scan
        timeout-minutes: 10
        continue-on-error: ${{ github.ref != 'refs/heads/main' }}
```

### Fallback Policies

| Scenario | Default Behavior | Override |
|----------|------------------|----------|
| Scanner unavailable | Block | Allow with warning (non-prod) |
| Timeout exceeded | Block | Allow with alert |
| Unknown error | Block | Escalate to security |

---

## Observability

### Metrics Collected

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `scan_duration_seconds` | Time per scan type | > 600s |
| `findings_count` | Findings by severity | Critical > 0 |
| `block_rate` | % builds blocked | > 20% |
| `false_positive_rate` | Reported FPs / total | > 10% |

### Log Aggregation

All pipeline logs shipped to central logging:

```yaml
# Structured logging format
{
  "timestamp": "2024-03-15T10:30:00Z",
  "pipeline_id": "12345",
  "stage": "security-scan",
  "tool": "trivy",
  "findings": 3,
  "severity_breakdown": {
    "critical": 0,
    "high": 2,
    "medium": 1
  },
  "result": "pass"
}
```

---

## Extension Points

### Adding New Scanners

1. Create new job in workflow
2. Define severity mapping
3. Configure blocking thresholds
4. Add to results aggregation
5. Update documentation

### Custom Policy Rules

1. Add Rego file to `src/policies/`
2. Write unit tests
3. Test locally with `conftest`
4. PR with policy documentation
5. Gradual rollout (warn → block)

---

## Related Documents

- [README.md](../README.md) — Overview
- [SECURITY_GATES.md](../SECURITY_GATES.md) — Gate details
- [PIPELINE_POLICY_MODEL.md](../PIPELINE_POLICY_MODEL.md) — Policy framework
- [docs/adr/](adr/) — Architecture decisions
