# Pipeline Scenarios & Demo Guide

This document describes the expected behavior of the secure CI/CD pipeline across different scenarios. Use this as a reference for interviews and demonstrations.

## Quick Reference

| Scenario | Trigger | Security Scans | Policy Check | Deploy |
|----------|---------|----------------|--------------|--------|
| Feature PR | `pull_request` | All run | Pass required | No deploy |
| Merge to main | `push` to main | All run | Pass required | Dev only |
| Tagged release | `push` tag `v*` | All run | Pass required | Full promotion |
| Scheduled audit | `schedule` | All run | Report only | No deploy |
| Manual dispatch | `workflow_dispatch` | All run | Configurable | Depends on config |

---

## Scenario 1: Clean Pull Request

**Trigger:** Developer opens PR with compliant code

**Expected Behavior:**

```
┌─────────────────────────────────────────────────────────────┐
│  PR: feat/add-payment-validation                            │
├─────────────────────────────────────────────────────────────┤
│  ✅ code-quality        → Tests pass, lint clean            │
│  ✅ security-scan       → No secrets, no critical vulns     │
│  ✅ build               → Image built successfully          │
│  ✅ container-security  → SBOM generated, image signed      │
│  ✅ policy-check        → All policies satisfied            │
│  ⏭️ deploy-*            → Skipped (PR only)                 │
├─────────────────────────────────────────────────────────────┤
│  Result: PR is mergeable                                    │
└─────────────────────────────────────────────────────────────┘
```

**Interview Talking Points:**
- "All security gates pass before code can be merged"
- "Deployment is blocked on PRs - only validation runs"
- "SBOM and signature are created but not pushed on PRs"

---

## Scenario 2: PR with Vulnerable Dependency

**Trigger:** Developer opens PR with known CVE in dependencies

**Expected Behavior:**

```
┌─────────────────────────────────────────────────────────────┐
│  PR: feat/use-old-lodash                                    │
├─────────────────────────────────────────────────────────────┤
│  ✅ code-quality        → Tests pass                        │
│  ❌ security-scan       → Snyk found CVE-2021-23337         │
│  ⏭️ build               → Skipped (security failed)         │
│  ⏭️ container-security  → Skipped                           │
│  ⏭️ policy-check        → Skipped                           │
│  ⏭️ deploy-*            → Skipped                           │
├─────────────────────────────────────────────────────────────┤
│  Result: PR blocked, requires remediation                   │
└─────────────────────────────────────────────────────────────┘
```

**GitHub Security Tab Shows:**
- SARIF results uploaded from Snyk
- CVE details with severity and remediation advice
- Link to vulnerable package and fixed version

**Interview Talking Points:**
- "Pipeline fails fast on critical vulnerabilities"
- "Developer gets immediate feedback in the PR"
- "Remediation guidance is provided via SARIF in Security tab"

---

## Scenario 3: PR with Hardcoded Secret

**Trigger:** Developer accidentally commits API key

**Expected Behavior:**

```
┌─────────────────────────────────────────────────────────────┐
│  PR: fix/update-api-client                                  │
├─────────────────────────────────────────────────────────────┤
│  ✅ code-quality        → Tests pass                        │
│  ❌ security-scan       → Gitleaks detected AWS secret      │
│  ⏭️ build               → Skipped                           │
│  ⏭️ container-security  → Skipped                           │
│  ⏭️ policy-check        → Skipped                           │
├─────────────────────────────────────────────────────────────┤
│  Result: PR blocked, secret must be rotated                 │
└─────────────────────────────────────────────────────────────┘
```

**Interview Talking Points:**
- "Secret detection runs before build to prevent leakage"
- "Even if caught here, the secret should be rotated"
- "Pre-commit hooks catch this locally before push"

---

## Scenario 4: PR with Policy Violation

**Trigger:** Deployment manifest uses :latest tag or runs as root

**Expected Behavior:**

```
┌─────────────────────────────────────────────────────────────┐
│  PR: deploy/update-k8s-manifest                             │
├─────────────────────────────────────────────────────────────┤
│  ✅ code-quality        → Passes                            │
│  ✅ security-scan       → No vulns                          │
│  ✅ build               → Image built                       │
│  ✅ container-security  → Image scanned                     │
│  ❌ policy-check        → OPA: "must not use :latest tag"   │
│  ⏭️ deploy-*            → Skipped                           │
├─────────────────────────────────────────────────────────────┤
│  Result: PR blocked, policy violation                       │
└─────────────────────────────────────────────────────────────┘
```

**Conftest Output Example:**
```
FAIL - deployment.yaml - kubernetes.deployment - Container 'api' must not use :latest tag
FAIL - deployment.yaml - kubernetes.deployment - Deployment must set runAsNonRoot: true
```

**Interview Talking Points:**
- "Policy-as-code catches misconfigurations before deployment"
- "OPA policies are unit tested like application code"
- "Clear error messages guide developers to fix issues"

---

## Scenario 5: Successful Merge to Main

**Trigger:** PR merged to main branch

**Expected Behavior:**

```
┌─────────────────────────────────────────────────────────────┐
│  Push: main (merge commit)                                  │
├─────────────────────────────────────────────────────────────┤
│  ✅ code-quality        → All tests pass                    │
│  ✅ security-scan       → Clean                             │
│  ✅ build               → Image: ghcr.io/org/app:sha-abc123 │
│  ✅ container-security  → SBOM attached, Cosign signed      │
│  ✅ policy-check        → All policies pass                 │
│  ✅ deploy-dev          → Deployed to dev environment       │
│  ⏸️ deploy-staging      → Awaiting approval                 │
│  ⏸️ deploy-prod         → Blocked until staging approved    │
├─────────────────────────────────────────────────────────────┤
│  Result: Deployed to dev, waiting for promotion             │
└─────────────────────────────────────────────────────────────┘
```

**Interview Talking Points:**
- "Dev gets automatic deployment on merge"
- "Staging and prod require explicit approval"
- "Every image is signed and has SBOM attestation"

---

## Scenario 6: Production Deployment

**Trigger:** Tagged release (v1.2.0)

**Expected Behavior:**

```
┌─────────────────────────────────────────────────────────────┐
│  Push: tag v1.2.0                                           │
├─────────────────────────────────────────────────────────────┤
│  ✅ code-quality        → All tests pass                    │
│  ✅ security-scan       → Clean                             │
│  ✅ build               → Image: ghcr.io/org/app:v1.2.0     │
│  ✅ container-security  → SBOM + Signature verified         │
│  ✅ policy-check        → Production policies pass          │
│  ✅ deploy-dev          → Deployed                          │
│  ✅ deploy-staging      → Approved → Deployed               │
│  ⏸️ deploy-prod         → Awaiting final approval           │
│  │                                                           │
│  │  [Approve] [Reject]                                       │
│  ✅ deploy-prod         → Signature verified → Deployed     │
├─────────────────────────────────────────────────────────────┤
│  Result: Full production deployment                         │
└─────────────────────────────────────────────────────────────┘
```

**Production Gate Includes:**
- Manual approval from designated reviewers
- Signature verification (Cosign)
- SBOM present in registry
- All policies satisfied

**Interview Talking Points:**
- "Production requires cryptographic proof of provenance"
- "We verify signatures before deployment, not just on build"
- "Manual approval ensures human oversight for prod"

---

## Scenario 7: Multi-Language Repository

**Trigger:** Push to repo with Node + Python + Terraform

**Expected Behavior (multi-language-security.yml):**

```
┌─────────────────────────────────────────────────────────────┐
│  detect-languages                                           │
│  ├─ has_node: true                                          │
│  ├─ has_python: true                                        │
│  ├─ has_terraform: true                                     │
│  └─ has_docker: true                                        │
├─────────────────────────────────────────────────────────────┤
│  ✅ universal-scans     → Gitleaks + Semgrep baseline       │
│  ✅ node-security       → npm audit + Snyk + Semgrep        │
│  ✅ python-security     → Safety + Bandit + Snyk            │
│  ⏭️ go-security         → Skipped (not detected)            │
│  ⏭️ java-security       → Skipped (not detected)            │
│  ⏭️ ruby-security       → Skipped (not detected)            │
│  ⏭️ dotnet-security     → Skipped (not detected)            │
│  ✅ container-security  → Hadolint + Snyk container         │
│  ✅ iac-security        → tfsec + Checkov + Snyk IaC        │
│  ✅ governance-gate     → Report-only mode                  │
│  ✅ security-summary    → Combined report                   │
├─────────────────────────────────────────────────────────────┤
│  Result: All detected languages scanned                     │
└─────────────────────────────────────────────────────────────┘
```

**Interview Talking Points:**
- "Auto-detection means no manual configuration per repo"
- "Unused language scanners are skipped to save time"
- "Governance gate allows flipping from report-only to blocking"

---

## Demo Walkthrough

### Step 1: Show the Clean Path
1. Open `examples/valid/deployment-secure.yaml`
2. Run `conftest test examples/valid/ -p src/policies/`
3. Show: "0 failures" - this passes all policies

### Step 2: Show the Blocked Path
1. Open `examples/invalid/deployment-insecure.yaml`
2. Run `conftest test examples/invalid/ -p src/policies/`
3. Show multiple violations with clear error messages

### Step 3: Show Policy Tests
1. Run `opa test src/policies/ -v`
2. Show all policy rules have unit tests
3. Explain: "Policies are tested like code"

### Step 4: Show Pipeline Summary
1. Point to `$GITHUB_STEP_SUMMARY` output
2. Show language detection, scan results, enforcement mode
3. Explain: "Single pane of glass for security posture"

---

## Environment Promotion Flow

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│   DEV    │────▶│ STAGING  │────▶│   PROD   │
└──────────┘     └──────────┘     └──────────┘
     │                │                │
     ▼                ▼                ▼
  Automatic       Approval         Approval +
  on merge        required         Signature
                                   verified
```

---

## Governance Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| **Report-Only** | Scans run, findings logged, pipeline passes | Initial adoption, visibility |
| **Warn** | Scans run, warnings shown, pipeline passes | Transition period |
| **Blocking** | Scans run, failures block deployment | Production enforcement |

Current mode is configured in `governance-gate` job and shown in pipeline summary.

---

## Quick Commands for Demo

```bash
# Run OPA policy tests
opa test src/policies/ -v

# Test valid examples
conftest test examples/valid/ -p src/policies/

# Test invalid examples (expect failures)
conftest test examples/invalid/ -p src/policies/

# Validate workflows
./tests/pipeline/validate-workflows.sh

# Run app tests
cd src/app && pnpm install && pnpm test
```
