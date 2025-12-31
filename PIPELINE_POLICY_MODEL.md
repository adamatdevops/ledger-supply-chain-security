# Pipeline Policy Model

This document describes the policy framework that governs the Atlas secure CI/CD pipeline — how decisions are made, enforced, and evolved.

---

## Policy Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                    Organization Policy                       │
│    (Security standards, compliance requirements)             │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Platform Policy                           │
│    (Atlas pipeline defaults, gate configurations)            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Application Policy                        │
│    (Service-specific overrides, exceptions)                  │
└─────────────────────────────────────────────────────────────┘
```

**Precedence**: Organization > Platform > Application

Lower levels can only be **more restrictive**, never less.

---

## Policy Types

### 1. Blocking Policies

Must pass for pipeline to continue. No bypass without explicit exception.

| Policy | Description | Enforcement |
|--------|-------------|-------------|
| No secrets | Credentials in code | Hard block |
| Critical CVE | Known critical vulnerabilities | Hard block (staging/prod) |
| Unsigned images | Missing cryptographic signature | Hard block (prod) |
| Policy violations | OPA rule failures | Hard block |

### 2. Warning Policies

Generate alerts but do not block. Tracked for trending.

| Policy | Description | Tracking |
|--------|-------------|----------|
| Medium severity findings | Non-critical issues | Security dashboard |
| Deprecated dependencies | End-of-life libraries | Tech debt backlog |
| Missing tests | Low test coverage | Quality metrics |

### 3. Informational Policies

Logged for visibility and auditing only.

| Policy | Description | Purpose |
|--------|-------------|---------|
| Scan duration | Time per scan stage | Performance tracking |
| Finding counts | Total issues found | Trend analysis |
| Tool versions | Scanner versions used | Reproducibility |

---

## Policy Enforcement Points

### Pre-Merge (PR)

```yaml
Checks:
  - SAST scan
  - Secret detection
  - Dependency audit
  - License compliance

Outcome:
  - Block merge if blocking policies fail
  - Add comments for warnings
  - Update PR status checks
```

### Post-Merge (Build)

```yaml
Checks:
  - Container vulnerability scan
  - SBOM generation
  - Image signing

Outcome:
  - Block artifact promotion if policies fail
  - Attach attestations to artifacts
  - Log all findings
```

### Pre-Deploy (Gate)

```yaml
Checks:
  - Policy validation (OPA)
  - Signature verification
  - Environment-specific rules

Outcome:
  - Block deployment if policies fail
  - Require approval for exceptions
  - Log deployment decisions
```

---

## Exception Framework

### Exception Types

| Type | Duration | Approval |
|------|----------|----------|
| Emergency | 24 hours | Security on-call |
| Short-term | 7 days | Security team |
| Extended | 30 days | Security + Engineering lead |
| Permanent | Indefinite | CISO approval |

### Exception Requirements

Every exception must have:

1. **Justification** — Why is this exception needed?
2. **Risk assessment** — What's the exposure?
3. **Mitigation** — What compensating controls exist?
4. **Expiration** — When does this expire?
5. **Owner** — Who is responsible?
6. **Tracking** — Issue/ticket reference

### Exception Record Format

```yaml
# .security-exceptions/CVE-2024-XXXX.yaml
exception:
  id: EXC-2024-001
  type: extended
  cve: CVE-2024-XXXX

  justification: |
    Library cannot be updated due to API breaking changes.
    Update planned for Q2 release.

  risk_assessment:
    severity: HIGH
    exploitability: LOW
    exposure: Internal services only

  mitigation:
    - WAF rule blocking exploit pattern
    - Network segmentation limiting access
    - Enhanced monitoring for anomalies

  expiration: 2024-06-01
  owner: security-team
  tracking: JIRA-1234
  approved_by: security-lead
  approved_date: 2024-03-01
```

---

## Policy-as-Code Implementation

### Directory Structure

```
src/policies/
├── common/
│   ├── severity-levels.rego
│   └── helpers.rego
├── container/
│   ├── security-context.rego
│   ├── resource-limits.rego
│   └── image-requirements.rego
├── deployment/
│   ├── environment-rules.rego
│   └── approval-gates.rego
└── tests/
    ├── container_test.rego
    └── deployment_test.rego
```

### Policy Testing

All policies must have tests:

```rego
# tests/container_test.rego
package container.security_test

import data.container.security

test_deny_root_user {
    security.deny["Container must not run as root"] with input as {
        "image": {"user": "root"}
    }
}

test_allow_non_root_user {
    count(security.deny) == 0 with input as {
        "image": {"user": "app"}
    }
}
```

Run tests:
```bash
opa test src/policies/ -v
```

### Policy Versioning

Policies are versioned alongside code:

```
v1.0.0 — Initial policy set
v1.1.0 — Added container security context rules
v1.2.0 — Updated CVE severity thresholds
v2.0.0 — Breaking: New exception format required
```

---

## Policy Lifecycle

### 1. Proposal

New policy proposed via PR:

```markdown
## Policy Proposal: Require resource limits

### Problem
Deployments without resource limits can cause node instability.

### Proposed Rule
All containers must specify CPU and memory limits.

### Impact
- ~15% of current deployments would fail
- Migration plan: 2-week warning period

### Enforcement
- Week 1-2: Warning only
- Week 3+: Blocking
```

### 2. Review

- Security team reviews for completeness
- Engineering reviews for feasibility
- Stakeholders review for impact

### 3. Rollout

Gradual enforcement:

```yaml
# Phase 1: Logging only
enforcement: log

# Phase 2: Warning
enforcement: warn

# Phase 3: Blocking (non-prod)
enforcement: block
environments: [dev, staging]

# Phase 4: Full enforcement
enforcement: block
environments: [dev, staging, prod]
```

### 4. Monitoring

Track policy effectiveness:

- Block rate trend
- False positive reports
- Exception requests
- Time to compliance

### 5. Evolution

Policies are living documents:

- Regular review (quarterly)
- Update based on new threats
- Retire obsolete rules
- Refine based on feedback

---

## Governance Model

### Policy Owners

| Domain | Owner | Responsibilities |
|--------|-------|------------------|
| Security policies | Security Team | Define, review, approve exceptions |
| Deployment policies | Platform Team | Define, implement, support |
| Application policies | Service Teams | Request exceptions, comply |

### Change Control

| Change Type | Approval Required |
|-------------|-------------------|
| New blocking policy | Security + Engineering Lead |
| Threshold adjustment | Security Team |
| Exception grant | Based on exception type |
| Policy retirement | Security + Stakeholder review |

### Audit Trail

All policy decisions logged:

```json
{
  "timestamp": "2024-03-15T10:30:00Z",
  "event": "policy_evaluation",
  "policy": "container/security-context",
  "result": "deny",
  "reason": "runAsRoot=true",
  "pipeline_id": "12345",
  "repository": "billing-service",
  "environment": "staging"
}
```

---

## Metrics & Reporting

### Policy Health Dashboard

| Metric | Description | Target |
|--------|-------------|--------|
| Policy coverage | % repos with policies enforced | 100% |
| Compliance rate | % builds passing all policies | > 90% |
| Mean time to comply | Avg fix time for violations | < 4 hours |
| Exception count | Active exceptions | Trending down |

### Monthly Security Review

Report includes:

1. Policy violation trends
2. Top violating repositories
3. Exception status
4. New policies introduced
5. Policies retired
6. Recommendations
