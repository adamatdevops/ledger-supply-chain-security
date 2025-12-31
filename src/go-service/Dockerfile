# =============================================================================
# Notification Service Dockerfile (Go)
# =============================================================================
# Multi-stage build for minimal Go container.
# Final image uses distroless for maximum security.
# =============================================================================

# -----------------------------------------------------------------------------
# Build Stage
# -----------------------------------------------------------------------------
FROM golang:1.21-alpine AS builder

# Install ca-certificates for HTTPS
RUN apk add --no-cache ca-certificates

WORKDIR /app

# Copy go mod files
COPY go.mod ./

# Download dependencies (none for this service, but good practice)
RUN go mod download

# Copy source
COPY *.go ./

# Build static binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -o /notification-service .

# -----------------------------------------------------------------------------
# Production Stage
# -----------------------------------------------------------------------------
FROM gcr.io/distroless/static-debian12:nonroot

# Labels for governance
LABEL org.opencontainers.image.title="notification-service"
LABEL org.opencontainers.image.description="Ledger Notification Service"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.vendor="ACME Corp"
LABEL org.opencontainers.image.source="https://github.com/acme-corp/ledger-supply-chain-security"
LABEL team="platform"

# Copy binary and certs
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /notification-service /notification-service

# Environment
ENV PORT=8082

# Expose port
EXPOSE 8082

# Run as non-root (distroless:nonroot sets UID 65532)
USER nonroot:nonroot

# Health check (distroless doesn't have curl, so we rely on orchestrator)
# For K8s: use livenessProbe with httpGet

# Start service
ENTRYPOINT ["/notification-service"]
