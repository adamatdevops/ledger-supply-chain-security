#!/bin/bash
# =============================================================================
# Language Detection Tests
# =============================================================================
# Tests the language detection logic from multi-language-security.yml
#
# Usage: ./tests/pipeline/test-language-detection.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "Language Detection Tests"
echo "========================================"
echo ""

# Track test results
PASSED=0
FAILED=0

# -----------------------------------------------------------------------------
# Helper: Create temporary test directory
# -----------------------------------------------------------------------------
setup_test_dir() {
    local test_name="$1"
    local test_dir="$FIXTURES_DIR/$test_name"
    rm -rf "$test_dir"
    mkdir -p "$test_dir"
    echo "$test_dir"
}

# -----------------------------------------------------------------------------
# Helper: Run language detection
# -----------------------------------------------------------------------------
detect_language() {
    local dir="$1"
    local language="$2"

    cd "$dir"

    case "$language" in
        node)
            [[ -f "package.json" ]] || [[ -f "package-lock.json" ]] || [[ -f "yarn.lock" ]] || [[ -f "pnpm-lock.yaml" ]]
            ;;
        python)
            [[ -f "requirements.txt" ]] || [[ -f "Pipfile" ]] || [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]
            ;;
        go)
            [[ -f "go.mod" ]] || [[ -f "go.sum" ]]
            ;;
        java)
            [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]
            ;;
        ruby)
            [[ -f "Gemfile" ]] || [[ -f "Gemfile.lock" ]]
            ;;
        dotnet)
            ls *.csproj 1> /dev/null 2>&1 || ls *.sln 1> /dev/null 2>&1
            ;;
        docker)
            [[ -f "Dockerfile" ]] || [[ -f "docker-compose.yml" ]] || [[ -f "docker-compose.yaml" ]]
            ;;
        terraform)
            find . -name "*.tf" -type f 2>/dev/null | grep -q . || [[ -d "terraform" ]]
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Test: assert
# -----------------------------------------------------------------------------
assert_detected() {
    local test_name="$1"
    local language="$2"
    local dir="$3"

    if detect_language "$dir" "$language"; then
        echo -e "${GREEN}✓ $test_name${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $test_name (expected $language to be detected)${NC}"
        ((FAILED++))
    fi
}

assert_not_detected() {
    local test_name="$1"
    local language="$2"
    local dir="$3"

    if ! detect_language "$dir" "$language"; then
        echo -e "${GREEN}✓ $test_name${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $test_name (expected $language to NOT be detected)${NC}"
        ((FAILED++))
    fi
}

# -----------------------------------------------------------------------------
# Test: Node.js Detection
# -----------------------------------------------------------------------------
echo -e "${YELLOW}Testing Node.js Detection...${NC}"

dir=$(setup_test_dir "node-package-json")
touch "$dir/package.json"
assert_detected "Detects package.json" "node" "$dir"

dir=$(setup_test_dir "node-package-lock")
touch "$dir/package-lock.json"
assert_detected "Detects package-lock.json" "node" "$dir"

dir=$(setup_test_dir "node-yarn-lock")
touch "$dir/yarn.lock"
assert_detected "Detects yarn.lock" "node" "$dir"

dir=$(setup_test_dir "node-pnpm-lock")
touch "$dir/pnpm-lock.yaml"
assert_detected "Detects pnpm-lock.yaml" "node" "$dir"

dir=$(setup_test_dir "node-empty")
assert_not_detected "Empty dir not detected as Node" "node" "$dir"

echo ""

# -----------------------------------------------------------------------------
# Test: Python Detection
# -----------------------------------------------------------------------------
echo -e "${YELLOW}Testing Python Detection...${NC}"

dir=$(setup_test_dir "python-requirements")
touch "$dir/requirements.txt"
assert_detected "Detects requirements.txt" "python" "$dir"

dir=$(setup_test_dir "python-pipfile")
touch "$dir/Pipfile"
assert_detected "Detects Pipfile" "python" "$dir"

dir=$(setup_test_dir "python-pyproject")
touch "$dir/pyproject.toml"
assert_detected "Detects pyproject.toml" "python" "$dir"

echo ""

# -----------------------------------------------------------------------------
# Test: Go Detection
# -----------------------------------------------------------------------------
echo -e "${YELLOW}Testing Go Detection...${NC}"

dir=$(setup_test_dir "go-mod")
touch "$dir/go.mod"
assert_detected "Detects go.mod" "go" "$dir"

dir=$(setup_test_dir "go-sum")
touch "$dir/go.sum"
assert_detected "Detects go.sum" "go" "$dir"

echo ""

# -----------------------------------------------------------------------------
# Test: Java Detection
# -----------------------------------------------------------------------------
echo -e "${YELLOW}Testing Java Detection...${NC}"

dir=$(setup_test_dir "java-maven")
touch "$dir/pom.xml"
assert_detected "Detects pom.xml" "java" "$dir"

dir=$(setup_test_dir "java-gradle")
touch "$dir/build.gradle"
assert_detected "Detects build.gradle" "java" "$dir"

echo ""

# -----------------------------------------------------------------------------
# Test: Docker Detection
# -----------------------------------------------------------------------------
echo -e "${YELLOW}Testing Docker Detection...${NC}"

dir=$(setup_test_dir "docker-dockerfile")
touch "$dir/Dockerfile"
assert_detected "Detects Dockerfile" "docker" "$dir"

dir=$(setup_test_dir "docker-compose")
touch "$dir/docker-compose.yml"
assert_detected "Detects docker-compose.yml" "docker" "$dir"

echo ""

# -----------------------------------------------------------------------------
# Test: Terraform Detection
# -----------------------------------------------------------------------------
echo -e "${YELLOW}Testing Terraform Detection...${NC}"

dir=$(setup_test_dir "tf-root")
touch "$dir/main.tf"
assert_detected "Detects root .tf file" "terraform" "$dir"

dir=$(setup_test_dir "tf-nested")
mkdir -p "$dir/infra/modules"
touch "$dir/infra/modules/vpc.tf"
assert_detected "Detects nested .tf file" "terraform" "$dir"

dir=$(setup_test_dir "tf-directory")
mkdir -p "$dir/terraform"
assert_detected "Detects terraform directory" "terraform" "$dir"

echo ""

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------
rm -rf "$FIXTURES_DIR"

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo "========================================"
echo -e "Tests passed: ${GREEN}$PASSED${NC}"
echo -e "Tests failed: ${RED}$FAILED${NC}"
echo "========================================"

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}All language detection tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some language detection tests failed.${NC}"
    exit 1
fi
