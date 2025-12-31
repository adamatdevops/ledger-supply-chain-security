# =============================================================================
# Valid Dockerfile Example
# =============================================================================
# This Dockerfile follows security best practices and passes all policy checks.
#
# Best Practices Demonstrated:
# - Multi-stage build for minimal final image
# - Non-root user
# - Distroless base image
# - HEALTHCHECK defined
# - No secrets in build args or env
# - Minimal attack surface
# - pnpm for efficient package management
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Build
# -----------------------------------------------------------------------------
FROM node:20-alpine AS builder

# Install pnpm via corepack
RUN corepack enable && corepack prepare pnpm@9.15.0 --activate

WORKDIR /app

# Copy package files first for better caching
COPY package.json pnpm-lock.yaml ./

# Install dependencies (including devDependencies for build)
RUN pnpm install --frozen-lockfile --ignore-scripts

# Copy source code
COPY src/ ./src/
COPY tsconfig.json ./

# Build the application
RUN pnpm run build

# Prune dev dependencies
RUN pnpm prune --prod

# -----------------------------------------------------------------------------
# Stage 2: Production
# -----------------------------------------------------------------------------
FROM gcr.io/distroless/nodejs20-debian12:nonroot

# Labels for governance
LABEL org.opencontainers.image.title="payments-api"
LABEL org.opencontainers.image.version="1.2.0"
LABEL org.opencontainers.image.vendor="ACME Corp"
LABEL org.opencontainers.image.source="https://github.com/acme-corp/ledger-supply-chain-security"
LABEL team="platform"

WORKDIR /app

# Copy built application from builder
COPY --from=builder --chown=nonroot:nonroot /app/node_modules ./node_modules
COPY --from=builder --chown=nonroot:nonroot /app/dist ./dist
COPY --from=builder --chown=nonroot:nonroot /app/package.json ./

# Set non-sensitive environment variables
ENV NODE_ENV=production
ENV PORT=8080

# Expose application port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD ["/nodejs/bin/node", "-e", "require('http').get('http://localhost:8080/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"]

# Run as non-root user (already set by distroless:nonroot)
USER nonroot

# Start the application
CMD ["dist/server.js"]
