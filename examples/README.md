# Policy Test Examples

This directory contains example configurations for testing OPA/Conftest policies.

## Directory Structure

```
examples/
├── valid/                    # Configurations that PASS all policies
│   ├── deployment-secure.yaml
│   ├── container-config.json
│   └── Dockerfile
└── invalid/                  # Configurations that FAIL policies (for testing)
    ├── deployment-insecure.yaml
    ├── deployment-missing-resources.yaml
    ├── container-root-user.json
    ├── container-latest-tag.json
    └── Dockerfile.insecure
```

## Running Policy Tests

### OPA Unit Tests

```bash
# Run all policy unit tests
opa test src/policies/ -v

# Run with coverage
opa test src/policies/ -v --coverage
```

### Conftest Validation

```bash
# Test valid examples (should pass)
conftest test examples/valid/ -p src/policies/

# Test invalid examples (should fail with violations)
conftest test examples/invalid/ -p src/policies/

# Test specific file
conftest test examples/invalid/deployment-insecure.yaml -p src/policies/
```

## Valid Examples

| File | Description |
|------|-------------|
| `deployment-secure.yaml` | Production-ready K8s deployment with all security controls |
| `container-config.json` | Container configuration passing all OPA checks |
| `Dockerfile` | Multi-stage build with distroless base, non-root user |

## Invalid Examples (For Demo)

| File | Violations |
|------|------------|
| `deployment-insecure.yaml` | Root user, privileged, no limits, hardcoded secrets, :latest tag |
| `deployment-missing-resources.yaml` | No memory/CPU limits or requests |
| `container-root-user.json` | Runs as root, privileged, secrets in env, no healthcheck |
| `container-latest-tag.json` | Unapproved registry, missing SBOM |
| `Dockerfile.insecure` | Full OS base, root user, hardcoded secrets, no healthcheck |

## Interview Demo

Use these examples to demonstrate:

1. **Policy Enforcement**: Show how `conftest` blocks insecure configurations
2. **Governance Gates**: Invalid examples trigger pipeline failures
3. **Security Posture**: Valid examples represent "golden path" standards
4. **Shift-Left Security**: Catch issues before deployment, not after

### Example Output

```bash
$ conftest test examples/invalid/deployment-insecure.yaml -p src/policies/

FAIL - examples/invalid/deployment-insecure.yaml - kubernetes.deployment - Deployment must set runAsNonRoot: true
FAIL - examples/invalid/deployment-insecure.yaml - kubernetes.deployment - Container 'app' must not run in privileged mode
FAIL - examples/invalid/deployment-insecure.yaml - kubernetes.deployment - Deployment must have label: team
FAIL - examples/invalid/deployment-insecure.yaml - kubernetes.deployment - Container 'app' must not use :latest tag
FAIL - examples/invalid/deployment-insecure.yaml - kubernetes.deployment - Container 'app' uses unapproved registry: docker.io/nginx:latest
FAIL - examples/invalid/deployment-insecure.yaml - kubernetes.deployment - Production deployments must have at least 2 replicas

6 tests, 0 passed, 0 warnings, 6 failures
```
