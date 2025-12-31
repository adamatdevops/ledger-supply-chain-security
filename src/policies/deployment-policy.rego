package kubernetes.deployment

# Kubernetes Deployment Security Policies
# These policies enforce security best practices for K8s deployments

# ============================================
# Security Context
# ============================================

deny[msg] {
    input.kind == "Deployment"
    not input.spec.template.spec.securityContext.runAsNonRoot
    msg := "Deployment must set runAsNonRoot: true"
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("Container '%s' must not run in privileged mode", [container.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    container.securityContext.allowPrivilegeEscalation == true
    msg := sprintf("Container '%s' must not allow privilege escalation", [container.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.securityContext.readOnlyRootFilesystem
    msg := sprintf("Container '%s' should use readOnlyRootFilesystem", [container.name])
}

# ============================================
# Resource Limits
# ============================================

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Container '%s' must have memory limits", [container.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("Container '%s' must have CPU limits", [container.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.requests.memory
    msg := sprintf("Container '%s' must have memory requests", [container.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.requests.cpu
    msg := sprintf("Container '%s' must have CPU requests", [container.name])
}

# ============================================
# Image Requirements
# ============================================

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    endswith(container.image, ":latest")
    msg := sprintf("Container '%s' must not use :latest tag", [container.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not contains(container.image, ":")
    msg := sprintf("Container '%s' must use a specific image tag", [container.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not approved_registry(container.image)
    msg := sprintf("Container '%s' uses unapproved registry: %s", [container.name, container.image])
}

approved_registry(image) {
    startswith(image, "ghcr.io/")
}

approved_registry(image) {
    startswith(image, "gcr.io/")
}

approved_registry(image) {
    contains(image, ".dkr.ecr.")
}

# ============================================
# Required Labels
# ============================================

required_labels := ["app", "version", "team"]

deny[msg] {
    input.kind == "Deployment"
    label := required_labels[_]
    not input.metadata.labels[label]
    msg := sprintf("Deployment must have label: %s", [label])
}

deny[msg] {
    input.kind == "Deployment"
    label := required_labels[_]
    not input.spec.template.metadata.labels[label]
    msg := sprintf("Pod template must have label: %s", [label])
}

# ============================================
# Probes
# ============================================

warn[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.livenessProbe
    msg := sprintf("Container '%s' should have a livenessProbe", [container.name])
}

warn[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.readinessProbe
    msg := sprintf("Container '%s' should have a readinessProbe", [container.name])
}

# ============================================
# Replicas
# ============================================

deny[msg] {
    input.kind == "Deployment"
    input.metadata.namespace == "production"
    input.spec.replicas < 2
    msg := "Production deployments must have at least 2 replicas"
}

warn[msg] {
    input.kind == "Deployment"
    input.spec.replicas == 1
    msg := "Single replica deployments are vulnerable to downtime"
}

# ============================================
# Pod Disruption Budget
# ============================================

warn[msg] {
    input.kind == "Deployment"
    input.spec.replicas > 1
    not has_pdb
    msg := "Deployments with multiple replicas should have a PodDisruptionBudget"
}

has_pdb {
    # This would check for existence of PDB in the same namespace
    # Simplified for example
    input.relatedObjects.podDisruptionBudget
}

# ============================================
# Network Policy
# ============================================

warn[msg] {
    input.kind == "Deployment"
    input.metadata.namespace != "kube-system"
    not has_network_policy
    msg := "Deployment should have an associated NetworkPolicy"
}

has_network_policy {
    input.relatedObjects.networkPolicy
}

# ============================================
# Service Account
# ============================================

deny[msg] {
    input.kind == "Deployment"
    input.spec.template.spec.serviceAccountName == "default"
    msg := "Deployment should not use the default service account"
}

deny[msg] {
    input.kind == "Deployment"
    input.spec.template.spec.automountServiceAccountToken == true
    not requires_api_access
    msg := "Deployment should set automountServiceAccountToken: false unless API access is required"
}

requires_api_access {
    input.metadata.annotations["requires-k8s-api"] == "true"
}

# ============================================
# Host Configuration
# ============================================

deny[msg] {
    input.kind == "Deployment"
    input.spec.template.spec.hostNetwork == true
    msg := "Deployment must not use host network"
}

deny[msg] {
    input.kind == "Deployment"
    input.spec.template.spec.hostPID == true
    msg := "Deployment must not use host PID namespace"
}

deny[msg] {
    input.kind == "Deployment"
    input.spec.template.spec.hostIPC == true
    msg := "Deployment must not use host IPC namespace"
}

# ============================================
# Environment Variables
# ============================================

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    env := container.env[_]
    contains(lower(env.name), "password")
    env.value != null
    msg := sprintf("Container '%s' has password in plain text env var: %s", [container.name, env.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    env := container.env[_]
    contains(lower(env.name), "secret")
    env.value != null
    not env.valueFrom
    msg := sprintf("Container '%s' has secret in plain text env var: %s", [container.name, env.name])
}
