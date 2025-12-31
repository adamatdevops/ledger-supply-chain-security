package container.security

# Container Security Policies
# These policies enforce security best practices for container images

default allow = false

# Main allow rule - all checks must pass
allow {
    no_critical_vulnerabilities
    no_root_user
    has_healthcheck
    no_privileged_mode
    resource_limits_set
}

# ============================================
# Vulnerability Checks
# ============================================

no_critical_vulnerabilities {
    input.vulnerabilities.critical == 0
}

no_high_vulnerabilities {
    input.vulnerabilities.high == 0
}

vulnerability_threshold_met {
    input.vulnerabilities.critical == 0
    input.vulnerabilities.high <= input.policy.max_high_vulns
}

# ============================================
# User Configuration
# ============================================

no_root_user {
    input.config.user != "root"
    input.config.user != "0"
    input.config.user != ""
}

deny[msg] {
    input.config.user == "root"
    msg := "Container must not run as root user"
}

deny[msg] {
    input.config.user == "0"
    msg := "Container must not run as UID 0"
}

deny[msg] {
    input.config.user == ""
    msg := "Container must specify a non-root user"
}

# ============================================
# Health Check
# ============================================

has_healthcheck {
    input.config.healthcheck != null
    input.config.healthcheck.test != null
}

warn[msg] {
    input.config.healthcheck == null
    msg := "Container should have a HEALTHCHECK defined"
}

# ============================================
# Privileged Mode
# ============================================

no_privileged_mode {
    not input.config.privileged
}

deny[msg] {
    input.config.privileged == true
    msg := "Container must not run in privileged mode"
}

# ============================================
# Resource Limits
# ============================================

resource_limits_set {
    input.config.resources.limits.memory != null
    input.config.resources.limits.cpu != null
}

warn[msg] {
    input.config.resources.limits.memory == null
    msg := "Container should have memory limits defined"
}

warn[msg] {
    input.config.resources.limits.cpu == null
    msg := "Container should have CPU limits defined"
}

# ============================================
# Image Source
# ============================================

approved_registry {
    startswith(input.image.name, "ghcr.io/")
}

approved_registry {
    startswith(input.image.name, "gcr.io/")
}

approved_registry {
    endswith(input.image.name, ".dkr.ecr.us-east-1.amazonaws.com/")
}

deny[msg] {
    not approved_registry
    msg := sprintf("Image must be from approved registry. Found: %s", [input.image.name])
}

# ============================================
# Base Image
# ============================================

uses_distroless {
    contains(input.image.base, "distroless")
}

uses_alpine {
    contains(input.image.base, "alpine")
}

uses_minimal_base {
    uses_distroless
}

uses_minimal_base {
    uses_alpine
}

warn[msg] {
    not uses_minimal_base
    msg := "Consider using a minimal base image (distroless or alpine)"
}

# ============================================
# Secrets in Environment
# ============================================

no_secrets_in_env {
    count(secrets_in_env) == 0
}

secrets_in_env[key] {
    some key
    input.config.env[key]
    contains(lower(key), "password")
}

secrets_in_env[key] {
    some key
    input.config.env[key]
    contains(lower(key), "secret")
}

secrets_in_env[key] {
    some key
    input.config.env[key]
    contains(lower(key), "api_key")
}

secrets_in_env[key] {
    some key
    input.config.env[key]
    contains(lower(key), "token")
}

deny[msg] {
    count(secrets_in_env) > 0
    msg := sprintf("Secrets detected in environment variables: %v", [secrets_in_env])
}

# ============================================
# Image Signing
# ============================================

image_signed {
    input.signature.verified == true
}

deny[msg] {
    input.policy.require_signature == true
    not image_signed
    msg := "Image must be cryptographically signed"
}

# ============================================
# SBOM Requirements
# ============================================

has_sbom {
    input.sbom != null
    input.sbom.components != null
}

deny[msg] {
    input.policy.require_sbom == true
    not has_sbom
    msg := "Image must have an SBOM attestation"
}
