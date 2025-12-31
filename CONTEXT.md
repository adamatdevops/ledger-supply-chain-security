# AI Context — Atlas Secure CI/CD Governance

## Purpose of This Repository

This repository is part of a **public technical portfolio** for a Senior DevOps / Platform / Infrastructure Engineer.

**Specific Focus:** Security-first CI/CD pipeline design for regulated environments.

Goals:

- Demonstrate **DevSecOps architecture thinking**, not just tool configuration
- Show experience with:
  - Shift-left security integration
  - SAST, SCA, container scanning orchestration
  - Policy-as-code for deployment gates
  - Compliance-driven pipeline design
- Provide a **clean, well-documented reference pattern** for interview discussions

This repo must **not** contain real company code, secrets, internal domains, or any confidential information.
It represents *patterns* and *experience*, not direct copies of production systems.

---

## Target Audience

- Security-conscious platform engineers
- DevSecOps architects
- Hiring managers evaluating security maturity
- Compliance teams reviewing automation approaches

Assume the reader is **technical and experienced**, but unfamiliar with this specific implementation.

---

## Design Principles

1. **Security as architecture, not afterthought**
   - Every stage has security considerations
   - Gates are explicit and documented
   - Trade-offs are acknowledged

2. **Realistic, but minimal**
   - Examples should feel like real enterprise pipelines
   - Avoid unnecessary complexity
   - Focus on demonstrating the pattern

3. **Compliance-aware**
   - Audit trails built-in
   - Policy decisions documented
   - Attestation and signing included

4. **Interview-ready**
   - Everything supports security-focused discussions
   - Clear decision rationale for "why this tool?"
   - Trade-off analysis included

---

## Security & Confidentiality Constraints

The AI assistant **must never**:

- Include real vulnerability findings or CVE details from actual scans
- Reference real company security incidents
- Include actual secrets, tokens, or credentials
- Copy real security policies from employers

All examples must use:

- Generic service names (`billing-service`, `api-gateway`)
- Placeholder domains (`example.com`)
- Synthetic vulnerability examples
- Fictional policy requirements

---

## Technologies Referenced

This repo demonstrates integration with:

- **CI/CD**: GitHub Actions
- **SAST**: Semgrep, CodeQL
- **Secret Detection**: Gitleaks, TruffleHog
- **Dependency Scanning**: Snyk, Dependabot
- **Container Scanning**: Snyk Container, Grype
- **SBOM**: Syft, CycloneDX
- **Policy**: OPA, Conftest, Rego
- **Signing**: Cosign, Sigstore

---

## Style Guidelines

When creating or editing content:

- Use **clear, modern security terminology**
- Reference established frameworks (OWASP, SLSA, NIST SSDF)
- Include rationale for tool choices
- Acknowledge limitations honestly
- Avoid marketing language

When unsure between comprehensive and minimal:
**Choose minimal but complete** — show the pattern, not every edge case.

---

## Interview Value

This repository should enable confident responses to:

- "How do you integrate security into CI/CD?"
- "What's your approach to software supply chain security?"
- "How do you handle compliance automation?"
- "Walk me through your DevSecOps architecture"
- "How do you balance security with developer velocity?"
