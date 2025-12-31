# =============================================================================
# Payments API Dockerfile
# =============================================================================
# Multi-stage build following security best practices.
# Designed to pass all container security policies.
# Uses pnpm for fast, efficient package management.
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Dependencies
# -----------------------------------------------------------------------------
FROM node:20-alpine AS deps

# Install pnpm
RUN corepack enable && corepack prepare pnpm@9.15.0 --activate

WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install production dependencies only
RUN pnpm install --frozen-lockfile --prod --ignore-scripts

# -----------------------------------------------------------------------------
# Stage 2: Production
# -----------------------------------------------------------------------------
FROM gcr.io/distroless/nodejs20-debian12:nonroot

# Labels for governance and traceability
LABEL org.opencontainers.image.title="payments-api"
LABEL org.opencontainers.image.description="Fintech Payments API"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.vendor="ACME Corp"
LABEL org.opencontainers.image.source="https://github.com/acme-corp/ledger-supply-chain-security"
LABEL org.opencontainers.image.licenses="MIT"
LABEL team="platform"
LABEL environment="production"

WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps --chown=nonroot:nonroot /app/node_modules ./node_modules

# Copy application code
COPY --chown=nonroot:nonroot *.js ./
COPY --chown=nonroot:nonroot routes/ ./routes/
COPY --chown=nonroot:nonroot package.json ./

# Environment variables (non-sensitive only)
ENV NODE_ENV=production
ENV PORT=8080

# Expose application port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD ["/nodejs/bin/node", "-e", "const http = require('http'); http.get('http://localhost:8080/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"]

# Run as non-root user (distroless:nonroot sets USER 65532)
USER nonroot

# Start application
CMD ["server.js"]
