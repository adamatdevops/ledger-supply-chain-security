# Threat Model

This document provides a lightweight threat analysis for the Atlas secure CI/CD pipeline, identifying potential threats and the controls that address them.

---

## Scope

### In Scope

- CI/CD pipeline components
- Security scanning tools and integrations
- Artifact storage and signing
- Deployment gates and policies
- Developer interactions with pipeline

### Out of Scope

- Application-level vulnerabilities (handled by scanners)
- Runtime security (not a build-time concern)
- Physical security
- Social engineering attacks

---

## Assets

| Asset | Description | Sensitivity |
|-------|-------------|-------------|
| Source Code | Application and infrastructure code | High |
| Secrets | API keys, credentials, tokens | Critical |
| Artifacts | Container images, packages | High |
| Pipeline Config | Workflow definitions, policies | High |
| Scan Results | Vulnerability findings | Medium |
| SBOM | Software inventory | Medium |
| Signing Keys | Artifact signing credentials | Critical |

---

## Threat Actors

| Actor | Motivation | Capability | Likelihood |
|-------|------------|------------|------------|
| External Attacker | Data theft, disruption | Medium-High | Medium |
| Malicious Insider | Data theft, sabotage | High | Low |
| Compromised Dependency | Supply chain attack | High | Medium |
| Automated Bot | Credential stuffing, scanning | Low-Medium | High |

---

## STRIDE Analysis

### Spoofing

**Threat**: Attacker impersonates legitimate user or service.

| Scenario | Control |
|----------|---------|
| Stolen developer credentials | MFA required for all accounts |
| Forged commit signatures | GPG commit signing (optional) |
| Fake CI runner | Runner authentication, OIDC |
| Impersonated artifact | Image signing with Cosign |

**Residual Risk**: Low with controls in place.

---

### Tampering

**Threat**: Unauthorized modification of code, config, or artifacts.

| Scenario | Control |
|----------|---------|
| Modified source code | Branch protection, code review |
| Altered pipeline config | PR required for workflow changes |
| Tampered artifacts | Cryptographic signing, SBOM |
| Changed scan results | Immutable logging, signed attestations |

**Residual Risk**: Low with integrity controls.

---

### Repudiation

**Threat**: Actor denies performing an action.

| Scenario | Control |
|----------|---------|
| Unauthorized deployment | Audit logging of all deployments |
| Exception approval | Tracked in ticketing system |
| Policy bypass | Logged with actor identity |
| Scan suppression | Ignore files version controlled |

**Residual Risk**: Very low with comprehensive logging.

---

### Information Disclosure

**Threat**: Sensitive information exposed to unauthorized parties.

| Scenario | Control |
|----------|---------|
| Secrets in code | Secret detection gate (Gitleaks) |
| Secrets in logs | Log masking, restricted access |
| Vulnerability details | Access-controlled scan reports |
| Internal architecture | Private repository, access controls |

**Residual Risk**: Medium. Secrets in logs remain a concern.

---

### Denial of Service

**Threat**: Pipeline availability disrupted.

| Scenario | Control |
|----------|---------|
| Scanner overload | Timeout limits, resource quotas |
| External service unavailable | Fail-open policies (configurable) |
| Repository unavailable | Distributed caching, retry logic |
| Malicious PR flood | Rate limiting, permissions |

**Residual Risk**: Medium. Availability is an operational concern.

---

### Elevation of Privilege

**Threat**: Attacker gains higher access than authorized.

| Scenario | Control |
|----------|---------|
| Pipeline token theft | Short-lived tokens, least privilege |
| Runner compromise | Ephemeral runners, isolation |
| Admin access abuse | Access reviews, separation of duties |
| Dependency injection | Pinned versions, hash verification |

**Residual Risk**: Low with least privilege design.

---

## Attack Scenarios

### Scenario 1: Supply Chain Attack

**Attack Path**:
1. Attacker compromises popular dependency
2. Malicious code injected in update
3. Dependency pulled during build
4. Malicious code runs with build privileges

**Controls**:
- Dependency scanning (Snyk)
- Lock files with hashes
- SBOM tracking
- Staged rollout of dependency updates
- Behavioral monitoring in production

**Detection**:
- New vulnerabilities in dependency scan
- Unexpected network calls during build
- SBOM diff between versions

---

### Scenario 2: Secret Injection

**Attack Path**:
1. Developer accidentally commits secret
2. Secret pushed to remote
3. Secret exposed in public repo or logs
4. Attacker harvests and uses credential

**Controls**:
- Pre-commit hooks (local detection)
- Gitleaks in PR validation
- Immediate pipeline failure on detection
- Automated alerting to security team
- Git history cleanup procedures

**Detection**:
- Gitleaks finding
- CloudTrail alerts on unusual API usage
- Credential monitoring services

---

### Scenario 3: Pipeline Bypass

**Attack Path**:
1. Attacker gains developer access
2. Modifies branch protection rules
3. Pushes directly to main
4. Deploys without security checks

**Controls**:
- Admin access requires MFA + approval
- Audit logging of setting changes
- Deployment requires signed artifact
- Post-deployment verification
- Anomaly detection on deployment patterns

**Detection**:
- Audit log alerts on protection changes
- Unsigned artifact blocked at deploy
- Unusual deployment source

---

### Scenario 4: Malicious Insider

**Attack Path**:
1. Trusted developer decides to cause harm
2. Introduces subtle backdoor in code
3. Code passes automated review
4. Backdoor reaches production

**Controls**:
- Mandatory code review (second pair of eyes)
- SAST scanning (catches known patterns)
- Behavioral analysis in production
- Least privilege access
- Background checks (HR control)

**Detection**:
- Unusual code patterns in review
- Runtime anomalies
- Access pattern analysis

---

## Trust Boundaries

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer Workstation                     │
│  (Untrusted - pre-commit hooks are advisory only)           │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Git Push
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                         │
│  (Semi-trusted - branch protection enforced)                │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Trigger
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    CI/CD Pipeline                            │
│  (Trusted - controlled environment, ephemeral)              │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Push Artifact
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Artifact Registry                         │
│  (Trusted - signed artifacts only)                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Deploy
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Production Environment                    │
│  (Highly trusted - multiple controls required)              │
└─────────────────────────────────────────────────────────────┘
```

---

## Control Summary

| Control Category | Controls Implemented |
|------------------|---------------------|
| **Authentication** | MFA, OIDC, short-lived tokens |
| **Authorization** | RBAC, least privilege, branch protection |
| **Integrity** | Signing, SBOM, hash verification |
| **Confidentiality** | Secret scanning, log masking, encryption |
| **Availability** | Timeouts, caching, fail-safe policies |
| **Audit** | Comprehensive logging, immutable trails |
| **Detection** | Automated scanning, anomaly alerts |

---

## Recommendations for Production

This threat model is illustrative. For production deployment:

1. **Conduct formal threat modeling** with security team
2. **Penetration test** the pipeline itself
3. **Add runtime security** (RASP, WAF)
4. **Implement SIEM integration** for correlation
5. **Establish incident response** procedures
6. **Regular red team exercises** against CI/CD

---

## Review Schedule

- **Quarterly**: Review threat landscape changes
- **After incidents**: Update based on learnings
- **After changes**: Re-assess when pipeline changes
- **Annually**: Full threat model refresh

---

## References

- [OWASP CI/CD Security Risks](https://owasp.org/www-project-top-10-ci-cd-security-risks/)
- [SLSA Supply Chain Levels](https://slsa.dev/)
- [CISA Software Supply Chain Security](https://www.cisa.gov/sbom)
