# Risk Notes

This document captures operational risks, limitations, and mitigation strategies for the Ledger supply chain security pipeline.

---

## Risk Categories

### R1: Tool Limitations

#### R1.1: False Negatives

**Risk**: Security scanners miss vulnerabilities that exist.

| Factor | Impact |
|--------|--------|
| Likelihood | Medium |
| Severity | High |
| Detection | Low (by definition) |

**Why It Happens**:
- Scanners rely on known vulnerability databases
- Zero-days are not detectable
- Business logic flaws are invisible to static analysis
- Custom code patterns may not match signatures

**Mitigation**:
- Layer multiple scanning tools
- Supplement with manual security review
- Conduct periodic penetration testing
- Maintain threat modeling practice
- Use defense in depth (runtime protection)

**Residual Risk**: Accepted. No automated tool provides 100% coverage.

---

#### R1.2: False Positives

**Risk**: Scanners report issues that aren't real vulnerabilities.

| Factor | Impact |
|--------|--------|
| Likelihood | High |
| Severity | Low |
| Detection | High |

**Why It Happens**:
- Pattern matching is imprecise
- Context is missing (dead code, test files)
- Vulnerability may not be exploitable in our context

**Mitigation**:
- Tune scanner rules for our codebase
- Maintain ignore files with documented rationale
- Regular review of suppressed findings
- Track false positive rate as metric

**Residual Risk**: Managed through tuning and exception process.

---

#### R1.3: Scanner Evasion

**Risk**: Malicious actors intentionally bypass scanners.

| Factor | Impact |
|--------|--------|
| Likelihood | Low |
| Severity | High |
| Detection | Low |

**Why It Happens**:
- Obfuscated code patterns
- Encoded secrets
- Novel attack techniques
- Insider threat

**Mitigation**:
- Code review requirements
- Multiple independent scanners
- Behavioral analysis in production
- Least privilege access controls
- Audit logging

**Residual Risk**: Accepted for portfolio context. Production would require additional controls.

---

### R2: Process Risks

#### R2.1: Exception Abuse

**Risk**: Exception process becomes a bypass mechanism.

| Factor | Impact |
|--------|--------|
| Likelihood | Medium |
| Severity | Medium |
| Detection | Medium |

**Why It Happens**:
- Pressure to deliver quickly
- Security seen as blocker
- Exceptions become permanent
- Inadequate tracking

**Mitigation**:
- Time-limited exceptions only
- Mandatory expiration dates
- Regular exception review (weekly)
- Exception metrics on dashboard
- Escalation path for repeat exceptions

**Residual Risk**: Managed through process discipline.

---

#### R2.2: Alert Fatigue

**Risk**: Too many warnings lead to ignored security findings.

| Factor | Impact |
|--------|--------|
| Likelihood | High |
| Severity | Medium |
| Detection | Medium |

**Why It Happens**:
- Overly sensitive scanners
- Accumulated technical debt
- Lack of prioritization
- No clear ownership

**Mitigation**:
- Severity-based routing (only critical alerts page)
- Dedicated security backlog
- SLOs for remediation time
- Trend analysis to identify systemic issues
- Regular noise reduction efforts

**Residual Risk**: Ongoing operational concern. Requires continuous tuning.

---

#### R2.3: Pipeline Bypass

**Risk**: Developers find ways to skip security checks.

| Factor | Impact |
|--------|--------|
| Likelihood | Low |
| Severity | High |
| Detection | Medium |

**Why It Happens**:
- Pipeline seen as obstacle
- Emergency deployments
- Misconfigured branch protection
- Insufficient access controls

**Mitigation**:
- Branch protection rules
- Required status checks
- Audit logging of all deployments
- No direct production access
- Regular access reviews

**Residual Risk**: Technical controls reduce likelihood significantly.

---

### R3: Infrastructure Risks

#### R3.1: Scanner Compromise

**Risk**: Security scanning tools themselves are compromised.

| Factor | Impact |
|--------|--------|
| Likelihood | Low |
| Severity | Critical |
| Detection | Low |

**Why It Happens**:
- Supply chain attack on scanner
- Malicious update pushed
- Scanner has broad code access

**Mitigation**:
- Pin scanner versions explicitly
- Verify checksums on download
- Isolate scanners in ephemeral environments
- Monitor for unexpected scanner behavior
- Use multiple independent tools

**Residual Risk**: Low likelihood, high impact. Requires vigilance.

---

#### R3.2: Secret Exposure in Logs

**Risk**: Secrets accidentally logged during scanning.

| Factor | Impact |
|--------|--------|
| Likelihood | Medium |
| Severity | High |
| Detection | Medium |

**Why It Happens**:
- Verbose logging during debug
- Error messages include context
- Third-party tools have different behaviors

**Mitigation**:
- Mask known secret patterns in logs
- Restrict log access
- Automated log scanning for secrets
- Short log retention
- Incident response for detected exposure

**Residual Risk**: Managed through layered controls.

---

#### R3.3: Availability Impact

**Risk**: Security scanning slows delivery or causes outages.

| Factor | Impact |
|--------|--------|
| Likelihood | Medium |
| Severity | Medium |
| Detection | High |

**Why It Happens**:
- Scanner service unavailable
- Long scan times
- Resource exhaustion
- External dependency failures

**Mitigation**:
- Timeout limits on scans
- Caching where appropriate
- Fallback policies (fail-open vs fail-closed)
- SLO for pipeline duration
- Self-hosted scanners for critical path

**Residual Risk**: Managed through operational practices.

---

## Risk Acceptance Summary

| Risk ID | Risk | Acceptance | Owner |
|---------|------|------------|-------|
| R1.1 | False negatives | Accepted with layered defense | Security |
| R1.2 | False positives | Managed through tuning | Platform |
| R1.3 | Scanner evasion | Accepted with monitoring | Security |
| R2.1 | Exception abuse | Managed through process | Security |
| R2.2 | Alert fatigue | Ongoing operational | Platform |
| R2.3 | Pipeline bypass | Mitigated technically | Platform |
| R3.1 | Scanner compromise | Low likelihood accepted | Security |
| R3.2 | Secret in logs | Managed through controls | Platform |
| R3.3 | Availability impact | Managed operationally | Platform |

---

## Review Schedule

This document should be reviewed:

- **Quarterly**: Full risk assessment review
- **After incidents**: Add new risks identified
- **After changes**: Update when pipeline changes
- **Annually**: Comprehensive risk reassessment

---

## Related Documents

- [THREAT_MODEL.md](THREAT_MODEL.md) — Threat analysis
- [SECURITY_GATES.md](SECURITY_GATES.md) — Gate configurations
- [docs/architecture.md](docs/architecture.md) — System architecture
