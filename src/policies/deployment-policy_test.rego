# =============================================================================
# Kubernetes Deployment Policy Tests
# =============================================================================
# Unit tests for deployment-policy.rego
# Run: opa test src/policies/ -v
# =============================================================================

package kubernetes.deployment

import rego.v1

# =============================================================================
# Test: Security Context - runAsNonRoot
# =============================================================================

test_deny_missing_run_as_non_root if {
    msg := "Deployment must set runAsNonRoot: true"
    msg in deny with input as {
        "kind": "Deployment",
        "spec": {
            "template": {
                "spec": {
                    "securityContext": {}
                }
            }
        }
    }
}

test_allow_run_as_non_root if {
    count(deny) == 0 with input as valid_deployment
}

# =============================================================================
# Test: Security Context - Privileged
# =============================================================================

test_deny_privileged_container if {
    count(deny) > 0 with input as {
        "kind": "Deployment",
        "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
        "spec": {
            "template": {
                "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
                "spec": {
                    "securityContext": {"runAsNonRoot": true},
                    "containers": [{
                        "name": "app",
                        "image": "ghcr.io/org/app:v1.0.0",
                        "securityContext": {
                            "privileged": true,
                            "readOnlyRootFilesystem": true,
                            "allowPrivilegeEscalation": false
                        },
                        "resources": {
                            "limits": {"memory": "128Mi", "cpu": "100m"},
                            "requests": {"memory": "64Mi", "cpu": "50m"}
                        }
                    }]
                }
            }
        }
    }
}

# =============================================================================
# Test: Security Context - Privilege Escalation
# =============================================================================

test_deny_privilege_escalation if {
    count(deny) > 0 with input as {
        "kind": "Deployment",
        "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
        "spec": {
            "template": {
                "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
                "spec": {
                    "securityContext": {"runAsNonRoot": true},
                    "containers": [{
                        "name": "app",
                        "image": "ghcr.io/org/app:v1.0.0",
                        "securityContext": {
                            "privileged": false,
                            "readOnlyRootFilesystem": true,
                            "allowPrivilegeEscalation": true
                        },
                        "resources": {
                            "limits": {"memory": "128Mi", "cpu": "100m"},
                            "requests": {"memory": "64Mi", "cpu": "50m"}
                        }
                    }]
                }
            }
        }
    }
}

# =============================================================================
# Test: Resource Limits
# =============================================================================

test_deny_missing_memory_limit if {
    count(deny) > 0 with input as {
        "kind": "Deployment",
        "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
        "spec": {
            "template": {
                "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
                "spec": {
                    "securityContext": {"runAsNonRoot": true},
                    "containers": [{
                        "name": "app",
                        "image": "ghcr.io/org/app:v1.0.0",
                        "securityContext": {
                            "privileged": false,
                            "readOnlyRootFilesystem": true,
                            "allowPrivilegeEscalation": false
                        },
                        "resources": {
                            "limits": {"cpu": "100m"},
                            "requests": {"memory": "64Mi", "cpu": "50m"}
                        }
                    }]
                }
            }
        }
    }
}

test_deny_missing_cpu_limit if {
    count(deny) > 0 with input as {
        "kind": "Deployment",
        "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
        "spec": {
            "template": {
                "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
                "spec": {
                    "securityContext": {"runAsNonRoot": true},
                    "containers": [{
                        "name": "app",
                        "image": "ghcr.io/org/app:v1.0.0",
                        "securityContext": {
                            "privileged": false,
                            "readOnlyRootFilesystem": true,
                            "allowPrivilegeEscalation": false
                        },
                        "resources": {
                            "limits": {"memory": "128Mi"},
                            "requests": {"memory": "64Mi", "cpu": "50m"}
                        }
                    }]
                }
            }
        }
    }
}

test_deny_missing_memory_request if {
    count(deny) > 0 with input as {
        "kind": "Deployment",
        "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
        "spec": {
            "template": {
                "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
                "spec": {
                    "securityContext": {"runAsNonRoot": true},
                    "containers": [{
                        "name": "app",
                        "image": "ghcr.io/org/app:v1.0.0",
                        "securityContext": {
                            "privileged": false,
                            "readOnlyRootFilesystem": true,
                            "allowPrivilegeEscalation": false
                        },
                        "resources": {
                            "limits": {"memory": "128Mi", "cpu": "100m"},
                            "requests": {"cpu": "50m"}
                        }
                    }]
                }
            }
        }
    }
}

# =============================================================================
# Test: Image Tags
# =============================================================================

test_deny_latest_tag if {
    msg := "Container 'app' must not use :latest tag"
    msg in deny with input as {
        "kind": "Deployment",
        "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
        "spec": {
            "template": {
                "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
                "spec": {
                    "securityContext": {"runAsNonRoot": true},
                    "containers": [{
                        "name": "app",
                        "image": "ghcr.io/org/app:latest",
                        "securityContext": {
                            "privileged": false,
                            "readOnlyRootFilesystem": true,
                            "allowPrivilegeEscalation": false
                        },
                        "resources": {
                            "limits": {"memory": "128Mi", "cpu": "100m"},
                            "requests": {"memory": "64Mi", "cpu": "50m"}
                        }
                    }]
                }
            }
        }
    }
}

test_deny_no_tag if {
    count(deny) > 0 with input as {
        "kind": "Deployment",
        "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
        "spec": {
            "template": {
                "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
                "spec": {
                    "securityContext": {"runAsNonRoot": true},
                    "containers": [{
                        "name": "app",
                        "image": "ghcr.io/org/app",
                        "securityContext": {
                            "privileged": false,
                            "readOnlyRootFilesystem": true,
                            "allowPrivilegeEscalation": false
                        },
                        "resources": {
                            "limits": {"memory": "128Mi", "cpu": "100m"},
                            "requests": {"memory": "64Mi", "cpu": "50m"}
                        }
                    }]
                }
            }
        }
    }
}

# =============================================================================
# Test: Approved Registry
# =============================================================================

test_deny_unapproved_registry if {
    count(deny) > 0 with input as {
        "kind": "Deployment",
        "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
        "spec": {
            "template": {
                "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
                "spec": {
                    "securityContext": {"runAsNonRoot": true},
                    "containers": [{
                        "name": "app",
                        "image": "docker.io/nginx:1.25",
                        "securityContext": {
                            "privileged": false,
                            "readOnlyRootFilesystem": true,
                            "allowPrivilegeEscalation": false
                        },
                        "resources": {
                            "limits": {"memory": "128Mi", "cpu": "100m"},
                            "requests": {"memory": "64Mi", "cpu": "50m"}
                        }
                    }]
                }
            }
        }
    }
}

test_allow_ghcr_registry if {
    approved_registry("ghcr.io/org/app:v1.0.0")
}

test_allow_gcr_registry if {
    approved_registry("gcr.io/project/app:v1.0.0")
}

test_allow_ecr_registry if {
    approved_registry("123456789.dkr.ecr.us-east-1.amazonaws.com/app:v1.0.0")
}

# =============================================================================
# Test: Required Labels
# =============================================================================

test_deny_missing_app_label if {
    msg := "Deployment must have label: app"
    msg in deny with input as {
        "kind": "Deployment",
        "metadata": {"labels": {"version": "v1", "team": "platform"}},
        "spec": {
            "template": {
                "metadata": {"labels": {"version": "v1", "team": "platform"}},
                "spec": {
                    "securityContext": {"runAsNonRoot": true},
                    "containers": []
                }
            }
        }
    }
}

test_deny_missing_version_label if {
    msg := "Deployment must have label: version"
    msg in deny with input as {
        "kind": "Deployment",
        "metadata": {"labels": {"app": "test", "team": "platform"}},
        "spec": {
            "template": {
                "metadata": {"labels": {"app": "test", "team": "platform"}},
                "spec": {
                    "securityContext": {"runAsNonRoot": true},
                    "containers": []
                }
            }
        }
    }
}

test_deny_missing_team_label if {
    msg := "Deployment must have label: team"
    msg in deny with input as {
        "kind": "Deployment",
        "metadata": {"labels": {"app": "test", "version": "v1"}},
        "spec": {
            "template": {
                "metadata": {"labels": {"app": "test", "version": "v1"}},
                "spec": {
                    "securityContext": {"runAsNonRoot": true},
                    "containers": []
                }
            }
        }
    }
}

# =============================================================================
# Test: Service Account
# =============================================================================

test_deny_default_service_account if {
    msg := "Deployment should not use the default service account"
    msg in deny with input as {
        "kind": "Deployment",
        "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
        "spec": {
            "template": {
                "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
                "spec": {
                    "serviceAccountName": "default",
                    "securityContext": {"runAsNonRoot": true},
                    "containers": []
                }
            }
        }
    }
}

# =============================================================================
# Test: Host Configuration
# =============================================================================

test_deny_host_network if {
    msg := "Deployment must not use host network"
    msg in deny with input as {
        "kind": "Deployment",
        "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
        "spec": {
            "template": {
                "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
                "spec": {
                    "hostNetwork": true,
                    "securityContext": {"runAsNonRoot": true},
                    "containers": []
                }
            }
        }
    }
}

test_deny_host_pid if {
    msg := "Deployment must not use host PID namespace"
    msg in deny with input as {
        "kind": "Deployment",
        "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
        "spec": {
            "template": {
                "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
                "spec": {
                    "hostPID": true,
                    "securityContext": {"runAsNonRoot": true},
                    "containers": []
                }
            }
        }
    }
}

test_deny_host_ipc if {
    msg := "Deployment must not use host IPC namespace"
    msg in deny with input as {
        "kind": "Deployment",
        "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
        "spec": {
            "template": {
                "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
                "spec": {
                    "hostIPC": true,
                    "securityContext": {"runAsNonRoot": true},
                    "containers": []
                }
            }
        }
    }
}

# =============================================================================
# Test: Environment Variables with Secrets
# =============================================================================

test_deny_password_in_env if {
    count(deny) > 0 with input as {
        "kind": "Deployment",
        "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
        "spec": {
            "template": {
                "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
                "spec": {
                    "securityContext": {"runAsNonRoot": true},
                    "containers": [{
                        "name": "app",
                        "image": "ghcr.io/org/app:v1.0.0",
                        "securityContext": {
                            "privileged": false,
                            "readOnlyRootFilesystem": true,
                            "allowPrivilegeEscalation": false
                        },
                        "resources": {
                            "limits": {"memory": "128Mi", "cpu": "100m"},
                            "requests": {"memory": "64Mi", "cpu": "50m"}
                        },
                        "env": [{"name": "DB_PASSWORD", "value": "secret123"}]
                    }]
                }
            }
        }
    }
}

# =============================================================================
# Test: Production Replicas
# =============================================================================

test_deny_single_replica_in_production if {
    msg := "Production deployments must have at least 2 replicas"
    msg in deny with input as {
        "kind": "Deployment",
        "metadata": {
            "namespace": "production",
            "labels": {"app": "test", "version": "v1", "team": "platform"}
        },
        "spec": {
            "replicas": 1,
            "template": {
                "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
                "spec": {
                    "securityContext": {"runAsNonRoot": true},
                    "containers": []
                }
            }
        }
    }
}

test_allow_multiple_replicas_in_production if {
    not deny["Production deployments must have at least 2 replicas"] with input as {
        "kind": "Deployment",
        "metadata": {
            "namespace": "production",
            "labels": {"app": "test", "version": "v1", "team": "platform"}
        },
        "spec": {
            "replicas": 3,
            "template": {
                "metadata": {"labels": {"app": "test", "version": "v1", "team": "platform"}},
                "spec": {
                    "securityContext": {"runAsNonRoot": true},
                    "containers": []
                }
            }
        }
    }
}

# =============================================================================
# Test: Probes (Warnings)
# =============================================================================

test_warn_missing_liveness_probe if {
    count(warn) > 0 with input as {
        "kind": "Deployment",
        "spec": {
            "template": {
                "spec": {
                    "containers": [{
                        "name": "app",
                        "readinessProbe": {"httpGet": {"path": "/ready", "port": 8080}}
                    }]
                }
            }
        }
    }
}

test_warn_missing_readiness_probe if {
    count(warn) > 0 with input as {
        "kind": "Deployment",
        "spec": {
            "template": {
                "spec": {
                    "containers": [{
                        "name": "app",
                        "livenessProbe": {"httpGet": {"path": "/health", "port": 8080}}
                    }]
                }
            }
        }
    }
}

# =============================================================================
# Test Fixture: Valid Deployment
# =============================================================================

valid_deployment := {
    "kind": "Deployment",
    "metadata": {
        "name": "secure-app",
        "namespace": "staging",
        "labels": {
            "app": "secure-app",
            "version": "v1.0.0",
            "team": "platform"
        }
    },
    "spec": {
        "replicas": 2,
        "template": {
            "metadata": {
                "labels": {
                    "app": "secure-app",
                    "version": "v1.0.0",
                    "team": "platform"
                }
            },
            "spec": {
                "serviceAccountName": "secure-app-sa",
                "automountServiceAccountToken": false,
                "securityContext": {
                    "runAsNonRoot": true
                },
                "containers": [{
                    "name": "app",
                    "image": "ghcr.io/org/secure-app:v1.0.0",
                    "securityContext": {
                        "privileged": false,
                        "allowPrivilegeEscalation": false,
                        "readOnlyRootFilesystem": true
                    },
                    "resources": {
                        "limits": {
                            "memory": "256Mi",
                            "cpu": "200m"
                        },
                        "requests": {
                            "memory": "128Mi",
                            "cpu": "100m"
                        }
                    },
                    "livenessProbe": {
                        "httpGet": {
                            "path": "/health",
                            "port": 8080
                        }
                    },
                    "readinessProbe": {
                        "httpGet": {
                            "path": "/ready",
                            "port": 8080
                        }
                    },
                    "env": [
                        {"name": "NODE_ENV", "value": "production"},
                        {"name": "PORT", "value": "8080"}
                    ]
                }]
            }
        }
    }
}

test_valid_deployment_passes if {
    count(deny) == 0 with input as valid_deployment
}
