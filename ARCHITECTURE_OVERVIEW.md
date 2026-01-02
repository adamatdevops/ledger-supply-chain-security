# Architecture Overview — Ledger Supply Chain Security

## Executive Summary

Ledger is a **security-first CI/CD pipeline architecture** designed for organizations that require:

- Automated security validation before deployment
- Audit trails for compliance requirements
- Consistent security policies across all repositories
- Software supply chain security

This is not a tool — it's a **pattern** for integrating security into delivery pipelines.

---

## The Problem

Traditional CI/CD pipelines treat security as:

- A separate team's responsibility
- A manual gate before production
- An afterthought bolted on at the end

This creates:

- **Bottlenecks**: Security review becomes a blocker
- **Late discovery**: Vulnerabilities found after significant investment
- **Inconsistency**: Different repos have different security postures
- **Compliance gaps**: No audit trail of security decisions

---

## The Ledger Approach

### Principle 1: Shift-Left by Default

Security scanning happens at the **earliest possible stage**:

```
Code → Scan → Build → Scan Again → Deploy
      ↑              ↑
   Fail fast    Verify artifacts
```

Benefits:
- Developers get feedback in minutes, not days
- Issues blocked before they reach shared branches
- Lower cost to fix (earlier = cheaper)

### Principle 2: Defense in Depth

No single tool catches everything. Ledger uses **layered scanning**:

| Layer | What It Catches | Tools |
|-------|-----------------|-------|
| Code | Logic flaws, injection patterns | Semgrep, CodeQL |
| Secrets | Hardcoded credentials | Gitleaks |
| Dependencies | Known CVEs in libraries | Snyk Open Source |
| Containers | OS-level vulnerabilities | Snyk Container |
| Policy | Deployment rule violations | OPA, Conftest |

### Principle 3: Policy-as-Code

Security policies are:

- **Version controlled** — changes are reviewed
- **Testable** — policies have unit tests
- **Auditable** — decisions are logged
- **Consistent** — same rules everywhere

Example policy (Rego):
```rego
deny[msg] {
    input.image.vulnerabilities.critical > 0
    msg := "Critical vulnerabilities found in container image"
}
```

### Principle 4: Trust Nothing, Verify Everything

Every artifact is:

- **Scanned** before and after build
- **Signed** with cryptographic attestation
- **Tracked** with SBOM generation
- **Verified** before deployment

---

## Pipeline Stages

### Stage 1: Pre-Commit (Local)

Before code leaves developer machine:
- Pre-commit hooks for secrets
- Local linting and formatting
- Quick SAST scan

### Stage 2: PR Validation

On pull request:
- Full SAST scan (Semgrep)
- Secret detection (Gitleaks)
- Dependency audit (Snyk)
- License compliance check

### Stage 3: Build & Package

After PR approval:
- Docker build with hardened base
- SBOM generation (Syft)
- Container signing (Cosign)
- Artifact upload

### Stage 4: Post-Build Verification

Before deployment eligibility:
- Container vulnerability scan
- Policy validation (OPA)
- Attestation verification

### Stage 5: Deployment Gate

Environment-specific controls:
- `dev`: Warnings only
- `staging`: Block on high severity
- `prod`: Block on medium+, require approval

---

## Security Gates Matrix

| Gate | Dev | Staging | Prod |
|------|-----|---------|------|
| SAST Critical | Warn | Block | Block |
| SAST High | Warn | Block | Block |
| SAST Medium | Warn | Warn | Block |
| Secret Detected | Block | Block | Block |
| Critical CVE | Warn | Block | Block |
| High CVE | Warn | Block | Block |
| No SBOM | Warn | Warn | Block |
| Unsigned Image | Warn | Block | Block |
| Policy Violation | Warn | Block | Block |

---

## Trade-offs & Decisions

### Why GitHub Actions?

- Native to most repositories
- Good security model (OIDC, secrets)
- Extensive marketplace
- Easy to audit and review

**Alternative considered**: GitLab CI, Jenkins
**Decision**: GitHub Actions for portfolio accessibility

### Why Semgrep over SonarQube?

- Faster execution
- Better custom rule support
- No server infrastructure
- Open source core

**Alternative considered**: SonarQube, CodeQL
**Decision**: Semgrep for speed and flexibility

### Why Snyk?

- Best-in-class developer experience
- Excellent fix recommendations and PRs
- Comprehensive scanning (code, deps, containers, IaC)
- Strong integration ecosystem (IDE, CI/CD, registries)
- Continuously updated vulnerability database

**Alternative considered**: Trivy, Grype, Anchore
**Decision**: Snyk for developer experience and actionable remediation

---

## What This Pattern Does NOT Do

- **Runtime protection**: This is build-time only
- **WAF/RASP**: No runtime application security
- **Penetration testing**: Automated scans are not pentests
- **Business logic flaws**: Tools can't understand intent
- **Zero-day detection**: Only known vulnerabilities

---

## When to Use This Pattern

**Good fit:**
- Regulated industries (Fintech, Healthcare)
- Enterprise with compliance requirements
- Teams scaling beyond manual review
- Organizations building supply chain security

**Poor fit:**
- Rapid prototyping (too much friction)
- Single-developer projects
- Internal-only tools with no compliance needs

---

## Metrics & Observability

Track pipeline health:

- **Mean time to remediation**: How fast are vulns fixed?
- **False positive rate**: Are developers ignoring alerts?
- **Block rate by stage**: Where do issues get caught?
- **Scan duration**: Is security slowing delivery?

---

## Further Reading

- [docs/architecture.md](docs/architecture.md) — Detailed technical architecture
- [SECURITY_GATES.md](SECURITY_GATES.md) — Gate configuration details
- [THREAT_MODEL.md](THREAT_MODEL.md) — Threat analysis
- [docs/adr/](docs/adr/) — Architecture Decision Records
