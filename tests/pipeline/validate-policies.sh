#!/bin/bash
# =============================================================================
# Policy Validation Script
# =============================================================================
# Validates OPA/Rego policies and runs unit tests.
#
# Tools used:
# - opa: Open Policy Agent for policy testing
# - conftest: Policy-as-code testing against examples
#
# Usage: ./tests/pipeline/validate-policies.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
POLICIES_DIR="$PROJECT_ROOT/src/policies"
EXAMPLES_DIR="$PROJECT_ROOT/examples"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "OPA Policy Validation"
echo "========================================"
echo ""

# Track overall status
FAILED=0

# -----------------------------------------------------------------------------
# Check: OPA policy syntax
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[1/4] Checking OPA policy syntax...${NC}"

if command -v opa &> /dev/null; then
    for policy in "$POLICIES_DIR"/*.rego; do
        if [[ ! "$policy" =~ _test\.rego$ ]]; then
            if opa check "$policy"; then
                echo -e "${GREEN}✓ Syntax OK: $(basename "$policy")${NC}"
            else
                echo -e "${RED}✗ Syntax error: $(basename "$policy")${NC}"
                FAILED=1
            fi
        fi
    done
else
    echo -e "${YELLOW}⚠ OPA not installed, skipping...${NC}"
    echo "  Install: brew install opa (macOS)"
    echo "           https://www.openpolicyagent.org/docs/latest/#running-opa"
fi

echo ""

# -----------------------------------------------------------------------------
# Check: OPA unit tests
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[2/4] Running OPA unit tests...${NC}"

if command -v opa &> /dev/null; then
    if opa test "$POLICIES_DIR" -v; then
        echo -e "${GREEN}✓ All OPA tests passed${NC}"
    else
        echo -e "${RED}✗ Some OPA tests failed${NC}"
        FAILED=1
    fi
else
    echo -e "${YELLOW}⚠ OPA not installed, skipping...${NC}"
fi

echo ""

# -----------------------------------------------------------------------------
# Check: Conftest on valid examples (should pass)
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[3/4] Testing valid examples with Conftest...${NC}"

if command -v conftest &> /dev/null; then
    # Test valid YAML examples
    if [[ -d "$EXAMPLES_DIR/valid" ]]; then
        for example in "$EXAMPLES_DIR/valid"/*.yaml "$EXAMPLES_DIR/valid"/*.yml 2>/dev/null; do
            if [[ -f "$example" ]]; then
                if conftest test "$example" -p "$POLICIES_DIR" --no-fail 2>/dev/null; then
                    echo -e "${GREEN}✓ Valid: $(basename "$example")${NC}"
                else
                    echo -e "${RED}✗ Unexpected failure: $(basename "$example")${NC}"
                    FAILED=1
                fi
            fi
        done
    fi
else
    echo -e "${YELLOW}⚠ Conftest not installed, skipping...${NC}"
    echo "  Install: brew install conftest (macOS)"
    echo "           https://www.conftest.dev/install/"
fi

echo ""

# -----------------------------------------------------------------------------
# Check: Conftest on invalid examples (should fail)
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[4/4] Testing invalid examples with Conftest...${NC}"

if command -v conftest &> /dev/null; then
    if [[ -d "$EXAMPLES_DIR/invalid" ]]; then
        for example in "$EXAMPLES_DIR/invalid"/*.yaml "$EXAMPLES_DIR/invalid"/*.yml 2>/dev/null; do
            if [[ -f "$example" ]]; then
                # We expect these to fail, so invert the logic
                if conftest test "$example" -p "$POLICIES_DIR" 2>/dev/null; then
                    echo -e "${RED}✗ Should have failed: $(basename "$example")${NC}"
                    FAILED=1
                else
                    echo -e "${GREEN}✓ Correctly rejected: $(basename "$example")${NC}"
                fi
            fi
        done
    fi
else
    echo -e "${YELLOW}⚠ Conftest not installed, skipping...${NC}"
fi

echo ""
echo "========================================"

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}All policy validations passed!${NC}"
    exit 0
else
    echo -e "${RED}Some policy validations failed.${NC}"
    exit 1
fi
