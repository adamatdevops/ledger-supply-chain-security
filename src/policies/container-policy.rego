package container.security

import rego.v1

# Container Security Policies
# These policies enforce security best practices for container images

default allow := false

# Main allow rule - all checks must pass
allow if {
    no_critical_vulnerabilities
    no_root_user
    has_healthcheck
    no_privileged_mode
    resource_limits_set
}

# ============================================
# Vulnerability Checks
# ============================================

no_critical_vulnerabilities if {
    input.vulnerabilities.critical == 0
}

no_high_vulnerabilities if {
    input.vulnerabilities.high == 0
}

vulnerability_threshold_met if {
    input.vulnerabilities.critical == 0
    input.vulnerabilities.high <= input.policy.max_high_vulns
}

# ============================================
# User Configuration
# ============================================

no_root_user if {
    input.config.user != "root"
    input.config.user != "0"
    input.config.user != ""
}

deny contains msg if {
    input.config.user == "root"
    msg := "Container must not run as root user"
}

deny contains msg if {
    input.config.user == "0"
    msg := "Container must not run as UID 0"
}

deny contains msg if {
    input.config.user == ""
    msg := "Container must specify a non-root user"
}

# ============================================
# Health Check
# ============================================

has_healthcheck if {
    input.config.healthcheck != null
    input.config.healthcheck.test != null
}

warn contains msg if {
    input.config.healthcheck == null
    msg := "Container should have a HEALTHCHECK defined"
}

# ============================================
# Privileged Mode
# ============================================

no_privileged_mode if {
    not input.config.privileged
}

deny contains msg if {
    input.config.privileged == true
    msg := "Container must not run in privileged mode"
}

# ============================================
# Resource Limits
# ============================================

resource_limits_set if {
    input.config.resources.limits.memory != null
    input.config.resources.limits.cpu != null
}

warn contains msg if {
    input.config.resources.limits.memory == null
    msg := "Container should have memory limits defined"
}

warn contains msg if {
    input.config.resources.limits.cpu == null
    msg := "Container should have CPU limits defined"
}

# ============================================
# Image Source
# ============================================

approved_registry if {
    startswith(input.image.name, "ghcr.io/")
}

approved_registry if {
    startswith(input.image.name, "gcr.io/")
}

approved_registry if {
    contains(input.image.name, ".dkr.ecr.")
}

deny contains msg if {
    not approved_registry
    msg := sprintf("Image must be from approved registry. Found: %s", [input.image.name])
}

# ============================================
# Base Image
# ============================================

uses_distroless if {
    contains(input.image.base, "distroless")
}

uses_alpine if {
    contains(input.image.base, "alpine")
}

uses_minimal_base if {
    uses_distroless
}

uses_minimal_base if {
    uses_alpine
}

warn contains msg if {
    not uses_minimal_base
    msg := "Consider using a minimal base image (distroless or alpine)"
}

# ============================================
# Secrets in Environment
# ============================================

no_secrets_in_env if {
    count(secrets_in_env) == 0
}

secrets_in_env contains key if {
    some key
    input.config.env[key]
    contains(lower(key), "password")
}

secrets_in_env contains key if {
    some key
    input.config.env[key]
    contains(lower(key), "secret")
}

secrets_in_env contains key if {
    some key
    input.config.env[key]
    contains(lower(key), "api_key")
}

secrets_in_env contains key if {
    some key
    input.config.env[key]
    contains(lower(key), "token")
}

deny contains msg if {
    count(secrets_in_env) > 0
    msg := sprintf("Secrets detected in environment variables: %v", [secrets_in_env])
}

# ============================================
# Image Signing
# ============================================

image_signed if {
    input.signature.verified == true
}

deny contains msg if {
    input.policy.require_signature == true
    not image_signed
    msg := "Image must be cryptographically signed"
}

# ============================================
# SBOM Requirements
# ============================================

has_sbom if {
    input.sbom != null
    input.sbom.components != null
}

deny contains msg if {
    input.policy.require_sbom == true
    not has_sbom
    msg := "Image must have an SBOM attestation"
}
