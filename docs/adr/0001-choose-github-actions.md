# ADR-0001: Choose GitHub Actions as CI/CD Platform

## Status

Accepted

## Date

2024-01-15

## Context

We need a CI/CD platform to orchestrate the secure pipeline. The platform must:

- Support complex multi-stage workflows
- Integrate with security scanning tools
- Provide secrets management
- Enable branch protection integration
- Support artifact signing and attestation
- Be accessible for portfolio demonstration

## Options Considered

### Option 1: GitHub Actions

**Pros**:
- Native GitHub integration (where code lives)
- OIDC support for keyless signing
- Excellent marketplace for actions
- Good security model (environment secrets, required reviewers)
- Free for public repos (portfolio-friendly)
- Declarative YAML workflows
- Matrix builds and reusable workflows

**Cons**:
- Vendor lock-in to GitHub
- Limited local testing (act is imperfect)
- Debugging can be challenging

### Option 2: GitLab CI

**Pros**:
- Tight GitLab integration
- Built-in container registry and security scanning
- Good on-premises option
- DAG-based pipeline definition

**Cons**:
- Requires GitLab (not where most code lives)
- Security features often require paid tiers
- Less ecosystem for portfolio visibility

### Option 3: Jenkins

**Pros**:
- Highly customizable
- Extensive plugin ecosystem
- Self-hosted (full control)
- Long track record

**Cons**:
- Requires infrastructure management
- Groovy scripting complexity
- Security patching burden
- Dated UI/UX
- Poor fit for portfolio demonstration

### Option 4: Buildkite / CircleCI

**Pros**:
- Clean configuration
- Good parallelization
- Hybrid self-hosted/cloud

**Cons**:
- Additional service to manage
- Less integration with GitHub features
- Cost for private usage

## Decision

**GitHub Actions**

Rationale:
1. **Native integration**: Branch protection, status checks, OIDC are seamless
2. **Portfolio fit**: Public repos with visible workflows are ideal for demonstration
3. **Ecosystem**: Abundant actions for security tools (Trivy, Cosign, Semgrep)
4. **Modern security**: OIDC for keyless signing is best-in-class
5. **Industry relevance**: Most candidates and employers use GitHub

## Consequences

### Positive
- Workflows are visible in repository (interview-friendly)
- Easy integration with all major security tools
- OIDC enables keyless signing (Sigstore/Cosign)
- Reusable workflows reduce duplication

### Negative
- Local testing limited to `act` (imperfect emulation)
- Dependent on GitHub availability
- Some advanced features require GitHub Enterprise

### Mitigations
- Design workflows to be portable where possible
- Use standard tool invocations (not GitHub-specific magic)
- Document what would change for other platforms

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Sigstore Cosign](https://docs.sigstore.dev/signing/quickstart/)
