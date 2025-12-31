# =============================================================================
# Container Policy Tests
# =============================================================================
# Unit tests for container-policy.rego
# Run: opa test src/policies/ -v
# =============================================================================

package container.security

# =============================================================================
# Test: No Root User
# =============================================================================

test_deny_root_user {
    msg := "Container must not run as root user"
    msg in deny with input as {"config": {"user": "root"}}
}

test_deny_uid_zero {
    msg := "Container must not run as UID 0"
    msg in deny with input as {"config": {"user": "0"}}
}

test_deny_empty_user {
    msg := "Container must specify a non-root user"
    msg in deny with input as {"config": {"user": ""}}
}

test_allow_non_root_user {
    no_root_user with input as {"config": {"user": "appuser"}}
}

test_allow_numeric_non_root_user {
    no_root_user with input as {"config": {"user": "1000"}}
}

# =============================================================================
# Test: No Privileged Mode
# =============================================================================

test_deny_privileged_mode {
    msg := "Container must not run in privileged mode"
    msg in deny with input as {"config": {"privileged": true}}
}

test_allow_unprivileged_mode {
    no_privileged_mode with input as {"config": {"privileged": false}}
}

test_allow_privileged_not_set {
    no_privileged_mode with input as {"config": {}}
}

# =============================================================================
# Test: Resource Limits
# =============================================================================

test_warn_missing_memory_limit {
    msg := "Container should have memory limits defined"
    msg in warn with input as {"config": {"resources": {"limits": {"cpu": "100m", "memory": null}}}}
}

test_warn_missing_cpu_limit {
    msg := "Container should have CPU limits defined"
    msg in warn with input as {"config": {"resources": {"limits": {"memory": "128Mi", "cpu": null}}}}
}

test_resource_limits_set {
    resource_limits_set with input as {
        "config": {
            "resources": {
                "limits": {
                    "memory": "128Mi",
                    "cpu": "100m"
                }
            }
        }
    }
}

# =============================================================================
# Test: Health Check
# =============================================================================

test_warn_missing_healthcheck {
    msg := "Container should have a HEALTHCHECK defined"
    msg in warn with input as {"config": {"healthcheck": null}}
}

test_has_healthcheck {
    has_healthcheck with input as {
        "config": {
            "healthcheck": {
                "test": ["CMD", "curl", "-f", "http://localhost/health"]
            }
        }
    }
}

# =============================================================================
# Test: Approved Registry
# =============================================================================

test_deny_unapproved_registry {
    count(deny) > 0 with input as {"image": {"name": "docker.io/nginx:latest"}}
}

test_allow_ghcr_registry {
    approved_registry with input as {"image": {"name": "ghcr.io/org/app:v1.0.0"}}
}

test_allow_gcr_registry {
    approved_registry with input as {"image": {"name": "gcr.io/project/app:v1.0.0"}}
}

test_allow_ecr_registry {
    approved_registry with input as {"image": {"name": "123456789.dkr.ecr.us-east-1.amazonaws.com/app:v1.0.0"}}
}

# =============================================================================
# Test: Secrets in Environment
# =============================================================================

test_deny_password_in_env {
    count(deny) > 0 with input as {
        "config": {
            "env": {
                "DATABASE_PASSWORD": "secret123"
            }
        }
    }
}

test_deny_secret_in_env {
    count(deny) > 0 with input as {
        "config": {
            "env": {
                "AWS_SECRET_KEY": "abcd1234"
            }
        }
    }
}

test_deny_api_key_in_env {
    count(deny) > 0 with input as {
        "config": {
            "env": {
                "API_KEY": "key123"
            }
        }
    }
}

test_deny_token_in_env {
    count(deny) > 0 with input as {
        "config": {
            "env": {
                "AUTH_TOKEN": "token123"
            }
        }
    }
}

test_allow_safe_env_vars {
    no_secrets_in_env with input as {
        "config": {
            "env": {
                "NODE_ENV": "production",
                "PORT": "3000",
                "LOG_LEVEL": "info"
            }
        }
    }
}

# =============================================================================
# Test: Image Signing
# =============================================================================

test_deny_unsigned_image_when_required {
    msg := "Image must be cryptographically signed"
    msg in deny with input as {
        "policy": {"require_signature": true},
        "signature": {"verified": false}
    }
}

test_allow_signed_image {
    image_signed with input as {
        "signature": {"verified": true}
    }
}

test_allow_unsigned_when_not_required {
    count(deny) == 0 with input as {
        "policy": {"require_signature": false},
        "signature": {"verified": false},
        "config": {"user": "appuser", "privileged": false},
        "image": {"name": "ghcr.io/org/app:v1.0.0"}
    }
}

# =============================================================================
# Test: SBOM Requirements
# =============================================================================

test_deny_missing_sbom_when_required {
    msg := "Image must have an SBOM attestation"
    msg in deny with input as {
        "policy": {"require_sbom": true},
        "sbom": null
    }
}

test_allow_sbom_present {
    has_sbom with input as {
        "sbom": {
            "components": [
                {"name": "express", "version": "4.18.0"}
            ]
        }
    }
}

# =============================================================================
# Test: Vulnerability Checks
# =============================================================================

test_no_critical_vulnerabilities_pass {
    no_critical_vulnerabilities with input as {
        "vulnerabilities": {"critical": 0, "high": 2}
    }
}

test_no_critical_vulnerabilities_fail {
    not no_critical_vulnerabilities with input as {
        "vulnerabilities": {"critical": 1, "high": 0}
    }
}

test_vulnerability_threshold_met {
    vulnerability_threshold_met with input as {
        "vulnerabilities": {"critical": 0, "high": 3},
        "policy": {"max_high_vulns": 5}
    }
}

test_vulnerability_threshold_exceeded {
    not vulnerability_threshold_met with input as {
        "vulnerabilities": {"critical": 0, "high": 10},
        "policy": {"max_high_vulns": 5}
    }
}

# =============================================================================
# Test: Base Image
# =============================================================================

test_uses_distroless {
    uses_minimal_base with input as {
        "image": {"base": "gcr.io/distroless/static:nonroot"}
    }
}

test_uses_alpine {
    uses_minimal_base with input as {
        "image": {"base": "node:18-alpine"}
    }
}

test_warn_non_minimal_base {
    msg := "Consider using a minimal base image (distroless or alpine)"
    msg in warn with input as {
        "image": {"base": "ubuntu:22.04"}
    }
}

# =============================================================================
# Test: Full Allow Rule
# =============================================================================

test_full_allow_pass {
    allow with input as {
        "vulnerabilities": {"critical": 0, "high": 0},
        "config": {
            "user": "appuser",
            "privileged": false,
            "healthcheck": {"test": ["CMD", "curl", "-f", "http://localhost/health"]},
            "resources": {
                "limits": {
                    "memory": "128Mi",
                    "cpu": "100m"
                }
            }
        }
    }
}

test_full_allow_fail_root_user {
    not allow with input as {
        "vulnerabilities": {"critical": 0, "high": 0},
        "config": {
            "user": "root",
            "privileged": false,
            "healthcheck": {"test": ["CMD", "curl", "-f", "http://localhost/health"]},
            "resources": {
                "limits": {
                    "memory": "128Mi",
                    "cpu": "100m"
                }
            }
        }
    }
}

test_full_allow_fail_critical_vulns {
    not allow with input as {
        "vulnerabilities": {"critical": 1, "high": 0},
        "config": {
            "user": "appuser",
            "privileged": false,
            "healthcheck": {"test": ["CMD", "curl", "-f", "http://localhost/health"]},
            "resources": {
                "limits": {
                    "memory": "128Mi",
                    "cpu": "100m"
                }
            }
        }
    }
}
