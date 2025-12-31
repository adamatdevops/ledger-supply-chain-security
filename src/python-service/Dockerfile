# =============================================================================
# Audit Service Dockerfile (Python)
# =============================================================================
# Minimal Python container for audit logging service.
# Follows security best practices: non-root, distroless-style, health checks.
# =============================================================================

FROM python:3.12-slim AS builder

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --target=/app/deps -r requirements.txt

# -----------------------------------------------------------------------------
# Production Stage
# -----------------------------------------------------------------------------
FROM python:3.12-slim

# Labels for governance
LABEL org.opencontainers.image.title="audit-service"
LABEL org.opencontainers.image.description="Ledger Audit Logging Service"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.vendor="ACME Corp"
LABEL org.opencontainers.image.source="https://github.com/acme-corp/ledger-supply-chain-security"
LABEL team="platform"

# Create non-root user
RUN groupadd --gid 1000 appgroup && \
    useradd --uid 1000 --gid appgroup --shell /bin/false appuser

WORKDIR /app

# Copy dependencies and application
COPY --from=builder /app/deps /app/deps
COPY --chown=appuser:appgroup app.py .

# Set Python path
ENV PYTHONPATH=/app/deps
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PORT=8081

# Expose port
EXPOSE 8081

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8081/health')" || exit 1

# Run as non-root
USER appuser

# Start service
CMD ["python", "app.py"]
