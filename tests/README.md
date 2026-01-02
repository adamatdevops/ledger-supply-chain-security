# Tests

This directory contains all tests for the ledger-supply-chain-security project.

## Directory Structure

```
tests/
├── pipeline/                      # Pipeline validation tests
│   ├── validate-workflows.sh      # GitHub Actions workflow validation
│   ├── validate-policies.sh       # OPA policy validation and testing
│   └── test-language-detection.sh # Language detection logic tests
└── README.md
```

## Running Tests

### All Pipeline Tests

```bash
# Run all pipeline validation tests
./tests/pipeline/validate-workflows.sh
./tests/pipeline/validate-policies.sh
./tests/pipeline/test-language-detection.sh
```

### Workflow Validation

Validates GitHub Actions workflow files:

```bash
./tests/pipeline/validate-workflows.sh
```

**Prerequisites:**
- `yamllint`: `pip install yamllint`
- `actionlint`: `brew install actionlint` (macOS)

### Policy Validation

Runs OPA unit tests and Conftest validation:

```bash
./tests/pipeline/validate-policies.sh
```

**Prerequisites:**
- `opa`: `brew install opa` (macOS)
- `conftest`: `brew install conftest` (macOS)

### Language Detection Tests

Tests the language detection logic from multi-language-security.yml:

```bash
./tests/pipeline/test-language-detection.sh
```

No external dependencies required.

## Application Tests

Application unit tests are located in `src/app/tests/`:

```bash
cd src/app
pnpm install
pnpm test
```

## OPA Policy Tests

OPA policy unit tests are in `src/policies/`:

```bash
# Run all policy tests
opa test src/policies/ -v

# Run with coverage
opa test src/policies/ -v --coverage
```

## Conftest Examples

Test policies against example configurations:

```bash
# Valid examples should pass
conftest test examples/valid/ -p src/policies/

# Invalid examples should fail
conftest test examples/invalid/ -p src/policies/
```

## CI/CD Integration

These tests are designed to run in CI/CD:

1. **Pre-commit hooks**: Run `validate-workflows.sh` and `validate-policies.sh`
2. **code-quality job**: Run application unit tests
3. **policy-check job**: Run OPA/Conftest validation
4. **security-scan job**: Run security scanners

## Test Coverage Goals

| Component | Target |
|-----------|--------|
| Application unit tests | > 80% |
| OPA policy tests | 100% of rules |
| Workflow validation | All workflow files |
| Language detection | All supported languages |
