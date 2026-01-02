#!/bin/bash
set -euo pipefail

# Local Security Scan Script
# Run this before pushing to catch issues early

echo "=========================================="
echo "  Ledger Local Security Scan"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track failures
FAILED=0

# ============================================
# Secret Detection
# ============================================
echo ""
echo "🔍 Running secret detection (Gitleaks)..."
if command -v gitleaks &> /dev/null; then
    if gitleaks detect --source . --no-git --verbose 2>/dev/null; then
        echo -e "${GREEN}✓ No secrets detected${NC}"
    else
        echo -e "${RED}✗ Secrets detected! Please remove before pushing.${NC}"
        FAILED=1
    fi
else
    echo -e "${YELLOW}⚠ Gitleaks not installed. Install with: brew install gitleaks${NC}"
fi

# ============================================
# SAST Scan
# ============================================
echo ""
echo "🔍 Running SAST scan (Semgrep)..."
if command -v semgrep &> /dev/null; then
    if semgrep --config=p/security-audit --config=p/owasp-top-ten . --quiet 2>/dev/null; then
        echo -e "${GREEN}✓ No SAST findings${NC}"
    else
        echo -e "${YELLOW}⚠ SAST findings detected. Review before pushing.${NC}"
        # Don't fail on SAST - just warn
    fi
else
    echo -e "${YELLOW}⚠ Semgrep not installed. Install with: pip install semgrep${NC}"
fi

# ============================================
# Dependency Scan
# ============================================
echo ""
echo "🔍 Running dependency scan (Snyk)..."
if command -v snyk &> /dev/null; then
    if snyk test --severity-threshold=high 2>/dev/null; then
        echo -e "${GREEN}✓ No high/critical vulnerabilities in dependencies${NC}"
    else
        echo -e "${RED}✗ High/critical vulnerabilities found in dependencies${NC}"
        FAILED=1
    fi
else
    echo -e "${YELLOW}⚠ Snyk not installed. Install with: npm install -g snyk${NC}"
    echo -e "${YELLOW}  Then authenticate with: snyk auth${NC}"
fi

# ============================================
# Docker Image Scan (if Dockerfile exists)
# ============================================
if [ -f "Dockerfile" ]; then
    echo ""
    echo "🔍 Running container scan (Snyk)..."
    if command -v snyk &> /dev/null && command -v docker &> /dev/null; then
        IMAGE_NAME="local-scan:latest"
        if docker build -t "$IMAGE_NAME" . --quiet 2>/dev/null; then
            if snyk container test "$IMAGE_NAME" --severity-threshold=high --file=Dockerfile 2>/dev/null; then
                echo -e "${GREEN}✓ No high/critical vulnerabilities in container${NC}"
            else
                echo -e "${RED}✗ High/critical vulnerabilities found in container${NC}"
                FAILED=1
            fi
            docker rmi "$IMAGE_NAME" --force >/dev/null 2>&1 || true
        else
            echo -e "${YELLOW}⚠ Docker build failed. Skipping container scan.${NC}"
        fi
    fi
fi

# ============================================
# Policy Validation
# ============================================
echo ""
echo "🔍 Running policy validation (OPA)..."
if command -v opa &> /dev/null; then
    if [ -d "src/policies" ]; then
        if opa test src/policies/ -v 2>/dev/null; then
            echo -e "${GREEN}✓ All policy tests passed${NC}"
        else
            echo -e "${RED}✗ Policy tests failed${NC}"
            FAILED=1
        fi
    else
        echo -e "${YELLOW}⚠ No policies directory found${NC}"
    fi
else
    echo -e "${YELLOW}⚠ OPA not installed. Install with: brew install opa${NC}"
fi

# ============================================
# Summary
# ============================================
echo ""
echo "=========================================="
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All security checks passed!${NC}"
    echo "=========================================="
    exit 0
else
    echo -e "${RED}✗ Some security checks failed.${NC}"
    echo "  Please fix issues before pushing."
    echo "=========================================="
    exit 1
fi
