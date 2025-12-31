#!/bin/bash
# =============================================================================
# Workflow Validation Script
# =============================================================================
# Validates GitHub Actions workflow files for syntax and best practices.
#
# Tools used:
# - yamllint: YAML syntax validation
# - actionlint: GitHub Actions specific validation
#
# Usage: ./tests/pipeline/validate-workflows.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKFLOWS_DIR="$PROJECT_ROOT/.github/workflows"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "GitHub Actions Workflow Validation"
echo "========================================"
echo ""

# Track overall status
FAILED=0

# -----------------------------------------------------------------------------
# Check: yamllint
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[1/3] Running yamllint...${NC}"

if command -v yamllint &> /dev/null; then
    if yamllint -c "$PROJECT_ROOT/.yamllint.yaml" "$WORKFLOWS_DIR"/*.yml; then
        echo -e "${GREEN}✓ yamllint passed${NC}"
    else
        echo -e "${RED}✗ yamllint failed${NC}"
        FAILED=1
    fi
else
    echo -e "${YELLOW}⚠ yamllint not installed, skipping...${NC}"
    echo "  Install: pip install yamllint"
fi

echo ""

# -----------------------------------------------------------------------------
# Check: actionlint
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[2/3] Running actionlint...${NC}"

if command -v actionlint &> /dev/null; then
    if actionlint "$WORKFLOWS_DIR"/*.yml; then
        echo -e "${GREEN}✓ actionlint passed${NC}"
    else
        echo -e "${RED}✗ actionlint failed${NC}"
        FAILED=1
    fi
else
    echo -e "${YELLOW}⚠ actionlint not installed, skipping...${NC}"
    echo "  Install: brew install actionlint (macOS)"
    echo "           go install github.com/rhysd/actionlint/cmd/actionlint@latest"
fi

echo ""

# -----------------------------------------------------------------------------
# Check: Required workflow files exist
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[3/3] Checking required workflow files...${NC}"

REQUIRED_WORKFLOWS=(
    "secure-pipeline.yml"
    "multi-language-security.yml"
)

for workflow in "${REQUIRED_WORKFLOWS[@]}"; do
    if [[ -f "$WORKFLOWS_DIR/$workflow" ]]; then
        echo -e "${GREEN}✓ Found: $workflow${NC}"
    else
        echo -e "${RED}✗ Missing: $workflow${NC}"
        FAILED=1
    fi
done

echo ""
echo "========================================"

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}All workflow validations passed!${NC}"
    exit 0
else
    echo -e "${RED}Some workflow validations failed.${NC}"
    exit 1
fi
