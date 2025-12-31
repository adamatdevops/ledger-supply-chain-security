# ADR-0002: Choose Snyk for Vulnerability Scanning

## Status

Accepted

## Date

2024-01-15

## Context

We need a vulnerability scanner that can:

- Scan dependencies for known CVEs
- Scan container images for OS and library vulnerabilities
- Provide actionable remediation guidance
- Integrate with CI/CD pipelines and developer workflows
- Support license compliance checking
- Scale across multiple repositories

## Options Considered

### Option 1: Snyk

**Pros**:
- Best-in-class developer experience
- Actionable fix recommendations with auto-fix PRs
- Comprehensive coverage: code, deps, containers, IaC
- Excellent IDE integrations (VS Code, IntelliJ)
- Strong CI/CD integration (GitHub, GitLab, Jenkins)
- Continuous monitoring with alerts
- Good license compliance features
- Well-documented API for automation
- Enterprise-grade reporting

**Cons**:
- Commercial product (requires license for full features)
- Requires API token/account
- Free tier has scanning limits
- Vendor dependency

### Option 2: Trivy (Aqua Security)

**Pros**:
- Fully open source (Apache 2.0)
- No account required
- Fast local scanning
- Multi-purpose: images, filesystems, IaC
- Active community

**Cons**:
- Less actionable remediation advice
- No automated fix PRs
- Limited continuous monitoring
- Weaker developer experience
- Less enterprise features

### Option 3: Grype (Anchore)

**Pros**:
- Fully open source
- Fast and lightweight
- Good SBOM integration (with Syft)

**Cons**:
- Container/SBOM focus only
- No code scanning
- No fix recommendations
- Smaller ecosystem

### Option 4: Dependabot (GitHub)

**Pros**:
- Free for GitHub repos
- Native GitHub integration
- Automated PRs for updates

**Cons**:
- Dependencies only (no containers)
- GitHub-specific
- Less detailed vulnerability info
- No continuous monitoring beyond deps

## Decision

**Snyk** as the primary vulnerability scanner.

Rationale:
1. **Developer Experience**: Fix recommendations and auto-PRs reduce friction
2. **Comprehensive**: Single tool for deps, containers, code, IaC
3. **Actionable**: Prioritized findings with clear remediation paths
4. **Integration**: Excellent GitHub Actions support
5. **Enterprise Ready**: Reporting, policies, SSO for team scaling
6. **Continuous Monitoring**: Alerts when new vulns affect existing projects

## Consequences

### Positive
- Developers get fix suggestions, not just alerts
- Auto-fix PRs accelerate remediation
- Single dashboard for all vulnerability types
- Continuous monitoring catches new CVEs automatically
- SARIF output integrates with GitHub Security tab
- License compliance included

### Negative
- Requires Snyk token (secret management)
- Free tier limits may require upgrade
- Vendor lock-in for some features
- External service dependency

### Mitigations
- Use organization-level Snyk token
- Monitor usage against tier limits
- Core scanning logic is portable (CLI-based)
- Supplement with open source tools for validation

## Implementation Notes

### GitHub Actions Integration

```yaml
- name: Snyk Dependency Scan
  uses: snyk/actions/node@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
  with:
    args: --severity-threshold=high

- name: Snyk Container Scan
  uses: snyk/actions/docker@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
  with:
    image: myapp:latest
    args: --file=Dockerfile
```

### Required Secrets

```
SNYK_TOKEN: Organization-level Snyk API token
```

### Policy Configuration

```yaml
# .snyk
version: v1.25.0
ignore:
  'SNYK-JS-EXAMPLE-123456':
    - '*':
        reason: 'False positive - not exploitable in our context'
        expires: 2024-06-01
```

## References

- [Snyk Documentation](https://docs.snyk.io/)
- [Snyk GitHub Actions](https://github.com/snyk/actions)
- [Snyk CLI](https://docs.snyk.io/snyk-cli)
- [Snyk vs Trivy Comparison](https://snyk.io/blog/snyk-vs-trivy/)
