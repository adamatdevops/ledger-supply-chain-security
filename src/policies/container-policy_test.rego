# =============================================================================
# Container Policy Tests
# =============================================================================
# Unit tests for container-policy.rego
# Run: opa test src/policies/ -v
# =============================================================================

package container.security

import rego.v1

# =============================================================================
# Test: No Root User
# =============================================================================

test_deny_root_user if {
    msg := "Container must not run as root user"
    msg in deny with input as {"config": {"user": "root"}}
}

test_deny_uid_zero if {
    msg := "Container must not run as UID 0"
    msg in deny with input as {"config": {"user": "0"}}
}

test_deny_empty_user if {
    msg := "Container must specify a non-root user"
    msg in deny with input as {"config": {"user": ""}}
}

test_allow_non_root_user if {
    no_root_user with input as {"config": {"user": "appuser"}}
}

test_allow_numeric_non_root_user if {
    no_root_user with input as {"config": {"user": "1000"}}
}

# =============================================================================
# Test: No Privileged Mode
# =============================================================================

test_deny_privileged_mode if {
    msg := "Container must not run in privileged mode"
    msg in deny with input as {"config": {"privileged": true}}
}

test_allow_unprivileged_mode if {
    no_privileged_mode with input as {"config": {"privileged": false}}
}

test_allow_privileged_not_set if {
    no_privileged_mode with input as {"config": {}}
}

# =============================================================================
# Test: Resource Limits
# =============================================================================

test_warn_missing_memory_limit if {
    msg := "Container should have memory limits defined"
    msg in warn with input as {"config": {"resources": {"limits": {"cpu": "100m", "memory": null}}}}
}

test_warn_missing_cpu_limit if {
    msg := "Container should have CPU limits defined"
    msg in warn with input as {"config": {"resources": {"limits": {"memory": "128Mi", "cpu": null}}}}
}

test_resource_limits_set if {
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

test_warn_missing_healthcheck if {
    msg := "Container should have a HEALTHCHECK defined"
    msg in warn with input as {"config": {"healthcheck": null}}
}

test_has_healthcheck if {
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

test_deny_unapproved_registry if {
    count(deny) > 0 with input as {"image": {"name": "docker.io/nginx:latest"}}
}

test_allow_ghcr_registry if {
    approved_registry with input as {"image": {"name": "ghcr.io/org/app:v1.0.0"}}
}

test_allow_gcr_registry if {
    approved_registry with input as {"image": {"name": "gcr.io/project/app:v1.0.0"}}
}

test_allow_ecr_registry if {
    approved_registry with input as {"image": {"name": "123456789012.dkr.ecr.us-east-1.amazonaws.com/app:v1.0.0"}}
}

# =============================================================================
# Test: Secrets in Environment
# =============================================================================

test_deny_password_in_env if {
    count(deny) > 0 with input as {
        "config": {
            "env": {
                "DATABASE_PASSWORD": "secret123"
            }
        }
    }
}

test_deny_secret_in_env if {
    count(deny) > 0 with input as {
        "config": {
            "env": {
                "AWS_SECRET_KEY": "abcd1234"
            }
        }
    }
}

test_deny_api_key_in_env if {
    count(deny) > 0 with input as {
        "config": {
            "env": {
                "API_KEY": "key123"
            }
        }
    }
}

test_deny_token_in_env if {
    count(deny) > 0 with input as {
        "config": {
            "env": {
                "AUTH_TOKEN": "token123"
            }
        }
    }
}

test_allow_safe_env_vars if {
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

test_deny_unsigned_image_when_required if {
    msg := "Image must be cryptographically signed"
    msg in deny with input as {
        "policy": {"require_signature": true},
        "signature": {"verified": false}
    }
}

test_allow_signed_image if {
    image_signed with input as {
        "signature": {"verified": true}
    }
}

test_allow_unsigned_when_not_required if {
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

test_deny_missing_sbom_when_required if {
    msg := "Image must have an SBOM attestation"
    msg in deny with input as {
        "policy": {"require_sbom": true},
        "sbom": null
    }
}

test_allow_sbom_present if {
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

test_no_critical_vulnerabilities_pass if {
    no_critical_vulnerabilities with input as {
        "vulnerabilities": {"critical": 0, "high": 2}
    }
}

test_no_critical_vulnerabilities_fail if {
    not no_critical_vulnerabilities with input as {
        "vulnerabilities": {"critical": 1, "high": 0}
    }
}

test_vulnerability_threshold_met if {
    vulnerability_threshold_met with input as {
        "vulnerabilities": {"critical": 0, "high": 3},
        "policy": {"max_high_vulns": 5}
    }
}

test_vulnerability_threshold_exceeded if {
    not vulnerability_threshold_met with input as {
        "vulnerabilities": {"critical": 0, "high": 10},
        "policy": {"max_high_vulns": 5}
    }
}

# =============================================================================
# Test: Base Image
# =============================================================================

test_uses_distroless if {
    uses_minimal_base with input as {
        "image": {"base": "gcr.io/distroless/static:nonroot"}
    }
}

test_uses_alpine if {
    uses_minimal_base with input as {
        "image": {"base": "node:18-alpine"}
    }
}

test_warn_non_minimal_base if {
    msg := "Consider using a minimal base image (distroless or alpine)"
    msg in warn with input as {
        "image": {"base": "ubuntu:22.04"}
    }
}

# =============================================================================
# Test: Full Allow Rule
# =============================================================================

test_full_allow_pass if {
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

test_full_allow_fail_root_user if {
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

test_full_allow_fail_critical_vulns if {
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
