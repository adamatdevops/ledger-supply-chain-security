# Security Gates Configuration

This document details the security gates implemented in the Ledger pipeline, their configuration, and enforcement behavior.

---

## Gate Overview

| Gate ID | Name | Stage | Blocking Behavior |
|---------|------|-------|-------------------|
| SG-001 | SAST Analysis | PR Validation | Configurable by severity |
| SG-002 | Secret Detection | PR Validation | Always blocking |
| SG-003 | Dependency Scan | PR Validation | Configurable by severity |
| SG-004 | License Compliance | PR Validation | Configurable by license type |
| SG-005 | Container Scan | Post-Build | Configurable by severity |
| SG-006 | SBOM Validation | Post-Build | Required for prod |
| SG-007 | Image Signing | Post-Build | Required for prod |
| SG-008 | Policy Validation | Pre-Deploy | Always blocking |

---

## SG-001: SAST Analysis

### Purpose
Detect security vulnerabilities in source code through static analysis.

### Tool
Semgrep with custom and community rulesets.

### Configuration

```yaml
# .semgrep/settings.yml
rules:
  - p/security-audit
  - p/owasp-top-ten
  - p/secrets
  - r/custom-rules

severity_threshold:
  dev: INFO      # Report all, block none
  staging: HIGH  # Block HIGH and CRITICAL
  prod: MEDIUM   # Block MEDIUM and above
```

### Blocking Matrix

| Severity | Dev | Staging | Prod |
|----------|-----|---------|------|
| CRITICAL | Warn | Block | Block |
| HIGH | Warn | Block | Block |
| MEDIUM | Warn | Warn | Block |
| LOW | Warn | Warn | Warn |
| INFO | Warn | - | - |

### Bypass Process

1. Security team review required
2. Risk acceptance documented
3. Time-limited exception (max 30 days)
4. Tracked in security backlog

---

## SG-002: Secret Detection

### Purpose
Prevent credentials, API keys, and tokens from being committed.

### Tool
Gitleaks with extended patterns.

### Configuration

```yaml
# .gitleaks.toml
[extend]
useDefault = true

[[rules]]
id = "custom-api-key"
description = "Custom API key pattern"
regex = '''(?i)api[_-]?key[_-]?=\s*['"]?[a-zA-Z0-9]{32,}'''
```

### Blocking Behavior

**Always blocking** — No exceptions without security team approval.

Any detected secret:
1. Blocks the pipeline immediately
2. Alerts security team
3. Requires credential rotation
4. Requires commit history cleanup

### False Positive Handling

```yaml
# .gitleaksignore
# Documented false positives only
docs/examples/fake-key-example.md:3
tests/fixtures/mock-credentials.json:*
```

---

## SG-003: Dependency Scan

### Purpose
Identify known vulnerabilities (CVEs) in third-party dependencies.

### Tool
Snyk Open Source for dependency analysis with fix recommendations.

### Configuration

```yaml
# .snyk policy file
version: v1.25.0
severity-threshold: high
fail-on: all
```

### CLI Usage
```bash
# Test for vulnerabilities
snyk test --severity-threshold=high

# Monitor project (continuous monitoring)
snyk monitor
```

### Blocking Matrix

| Severity | Dev | Staging | Prod |
|----------|-----|---------|------|
| CRITICAL | Warn | Block | Block |
| HIGH | Warn | Block | Block |
| MEDIUM | Warn | Warn | Block |
| LOW | Warn | Warn | Warn |

### Exception Handling

Documented exceptions in `.snyk` policy file:

```yaml
# .snyk
version: v1.25.0
ignore:
  'SNYK-JS-EXAMPLE-1234567':
    - '*':
        reason: 'No exploit available, mitigation in place'
        expires: 2024-03-01
        created: 2024-01-15
```

---

## SG-004: License Compliance

### Purpose
Ensure dependencies comply with organizational license policies.

### Tool
Snyk license compliance scanning.

### Policy

| License Category | Allowed | Notes |
|------------------|---------|-------|
| MIT, Apache-2.0, BSD | Yes | Permissive |
| MPL-2.0 | Review | File-level copyleft |
| LGPL | Review | Dynamic linking OK |
| GPL | No | Copyleft incompatible |
| AGPL | No | Network copyleft |
| Unknown | Review | Requires investigation |

### Configuration

```yaml
# license-policy.yaml
allowed:
  - MIT
  - Apache-2.0
  - BSD-2-Clause
  - BSD-3-Clause
  - ISC

review_required:
  - MPL-2.0
  - LGPL-2.1
  - LGPL-3.0

denied:
  - GPL-2.0
  - GPL-3.0
  - AGPL-3.0
```

---

## SG-005: Container Scan

### Purpose
Identify vulnerabilities in container images (base OS + installed packages).

### Tool
Snyk Container for image vulnerability scanning.

### Scan Targets

1. **Base image** — Before application layers
2. **Final image** — Complete built image
3. **Runtime config** — Dockerfile best practices

### Configuration

```bash
# Scan container image
snyk container test myapp:latest --severity-threshold=high

# Monitor container for new vulnerabilities
snyk container monitor myapp:latest

# Scan with Dockerfile for better remediation advice
snyk container test myapp:latest --file=Dockerfile
```

### Snyk Container Features

| Feature | Description |
|---------|-------------|
| Base image recommendations | Suggests smaller/more secure base images |
| Layer analysis | Shows which layer introduced vulnerability |
| Fix PRs | Automated PRs to upgrade base images |
| Dockerfile analysis | Checks for misconfigurations |

### Dockerfile Checks

| Check | Severity | Description |
|-------|----------|-------------|
| Running as root | HIGH | Container should use non-root user |
| Latest tag | MEDIUM | Use specific version tags |
| No healthcheck | LOW | Add HEALTHCHECK instruction |
| Secrets in ENV | CRITICAL | Never put secrets in ENV |

---

## SG-006: SBOM Validation

### Purpose
Generate and validate Software Bill of Materials for supply chain transparency.

### Tool
Syft for SBOM generation, Grype for validation.

### Format
CycloneDX 1.5 (JSON)

### Requirements

| Environment | SBOM Required | Attestation Required |
|-------------|---------------|---------------------|
| Dev | No | No |
| Staging | Yes | No |
| Prod | Yes | Yes |

### Validation Checks

1. **Completeness** — All components identified
2. **Format compliance** — Valid CycloneDX schema
3. **Signature** — SBOM is signed (prod only)
4. **Freshness** — Generated within pipeline run

---

## SG-007: Image Signing

### Purpose
Cryptographically sign container images for integrity verification.

### Tool
Cosign (Sigstore)

### Signing Flow

```
Build Image → Generate SBOM → Sign Image → Attach SBOM → Push
                                  ↓
                            Verify on Deploy
```

### Verification Policy

```yaml
# cosign-policy.yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: ledger-signed-images
spec:
  images:
    - glob: "ghcr.io/example-org/*"
  authorities:
    - keyless:
        identities:
          - issuer: https://token.actions.githubusercontent.com
            subject: https://github.com/example-org/*
```

---

## SG-008: Policy Validation

### Purpose
Enforce organizational deployment policies using policy-as-code.

### Tool
OPA/Conftest with Rego policies.

### Policy Categories

| Category | Examples |
|----------|----------|
| Resource limits | CPU/memory requirements |
| Security context | Non-root, read-only fs |
| Networking | Allowed ports, egress rules |
| Labels | Required metadata |
| Compliance | Environment-specific rules |

### Example Policy

```rego
package kubernetes.admission

deny[msg] {
    input.kind == "Deployment"
    not input.spec.template.spec.securityContext.runAsNonRoot
    msg := "Deployments must set runAsNonRoot: true"
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Container %s must have memory limits", [container.name])
}
```

---

## Gate Metrics

Track gate effectiveness:

| Metric | Description | Target |
|--------|-------------|--------|
| Block rate | % of builds blocked by gate | < 10% |
| False positive rate | Invalid blocks / total blocks | < 5% |
| Mean time to fix | Avg time from block to resolution | < 4 hours |
| Bypass rate | Exceptions granted / total blocks | < 2% |

---

## Escalation Path

When a gate blocks incorrectly:

1. Developer opens bypass request
2. Security team reviews within 4 hours
3. If valid: temporary exception granted
4. Root cause added to backlog
5. Gate rules updated to prevent recurrence
