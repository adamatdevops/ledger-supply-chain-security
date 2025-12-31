# ADR-0003: Choose Semgrep for Static Application Security Testing

## Status

Accepted

## Date

2024-01-15

## Context

We need a Static Application Security Testing (SAST) tool that can:

- Detect security vulnerabilities in source code
- Run quickly in CI/CD pipelines
- Support multiple programming languages
- Allow custom rule creation
- Integrate with GitHub (PR comments, status checks)
- Be cost-effective for portfolio demonstration

## Options Considered

### Option 1: Semgrep

**Pros**:
- Open source core (LGPL-2.1)
- Fast execution (incremental scanning)
- Excellent custom rule support (YAML-based)
- Multi-language (30+ languages)
- Low false positive rate (pattern-based, not symbolic)
- Active community rulesets
- No build required (AST-based)
- GitHub Action available

**Cons**:
- Advanced features require Semgrep Cloud (paid)
- Less deep analysis than symbolic execution tools
- Community rules vary in quality

### Option 2: SonarQube / SonarCloud

**Pros**:
- Comprehensive quality + security analysis
- Good visualization dashboard
- Wide language support
- Established enterprise tool

**Cons**:
- Requires server (SonarQube) or account (SonarCloud)
- Slower analysis
- Security rules often require paid edition
- Complex setup for self-hosted
- Less flexible custom rules

### Option 3: CodeQL (GitHub)

**Pros**:
- Deep semantic analysis
- Free for public repos
- Native GitHub integration
- Powerful query language

**Cons**:
- Requires build (for compiled languages)
- Slower execution
- Query language has learning curve
- GitHub-specific

### Option 4: Bandit (Python) / Brakeman (Ruby) / etc.

**Pros**:
- Language-specific depth
- Simple to run
- Well-established

**Cons**:
- One tool per language (pipeline complexity)
- Inconsistent rule formats
- Harder to maintain unified policy

### Option 5: Checkmarx / Fortify

**Pros**:
- Enterprise-grade depth
- Comprehensive coverage
- Compliance certifications

**Cons**:
- Very expensive
- Complex deployment
- Slow scan times
- Not suitable for portfolio/demo

## Decision

**Semgrep** for primary SAST, complemented by CodeQL for deeper analysis.

Rationale:
1. **Speed**: Incremental scanning keeps CI fast
2. **Custom rules**: YAML rules are accessible and maintainable
3. **Open source**: Core functionality freely available
4. **Multi-language**: Single tool for polyglot repos
5. **Low noise**: Pattern matching reduces false positives
6. **Community**: Rich ruleset library (OWASP, security-audit)

## Consequences

### Positive
- Fast feedback in PRs (< 2 min for typical repos)
- Custom rules can encode organizational knowledge
- Easy to explain in interviews (YAML is readable)
- Community rules provide good baseline coverage
- Integrates well with GitHub status checks

### Negative
- Misses some deep semantic issues (taint tracking limited)
- Community rules need vetting for quality
- Some advanced patterns require Semgrep Pro

### Mitigations
- Use CodeQL for periodic deep scans (weekly)
- Curate community rules rather than using all
- Write custom rules for high-value patterns
- Manual review for critical code paths

## Rule Configuration

```yaml
# .semgrep.yml
rules:
  # Community rulesets
  - p/security-audit
  - p/owasp-top-ten
  - p/secrets

  # Exclude noisy rules
  - '-r/generic.secrets.security.detected-generic-secret'

  # Custom organizational rules
  - ./semgrep-rules/
```

## Custom Rule Example

```yaml
# semgrep-rules/no-eval.yml
rules:
  - id: no-eval-usage
    patterns:
      - pattern: eval($X)
    message: "eval() is dangerous and should not be used"
    severity: ERROR
    languages: [python, javascript]
    metadata:
      category: security
      cwe: "CWE-95: Improper Neutralization of Directives in Dynamically Evaluated Code"
```

## Pipeline Integration

```yaml
- name: Semgrep SAST Scan
  uses: semgrep/semgrep-action@v1
  with:
    config: >-
      p/security-audit
      p/owasp-top-ten
      .semgrep.yml
```

## References

- [Semgrep Documentation](https://semgrep.dev/docs/)
- [Semgrep Registry](https://semgrep.dev/explore)
- [Semgrep vs CodeQL Comparison](https://semgrep.dev/docs/faq/#how-is-semgrep-different-from-codeql)
- [Writing Custom Rules](https://semgrep.dev/docs/writing-rules/overview/)
