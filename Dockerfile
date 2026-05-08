# =========================================================================
# Pelxa — Multi-stage Dockerfile
#
# Stage 1: build  — install all deps, compile Tailwind CSS for production.
# Stage 2: runtime — slim image with only prod deps + compiled assets.
#
# Run as non-root user, expose 3000, ship a HEALTHCHECK on /healthz.
# =========================================================================

# ---------- Stage 1: build ----------
FROM node:20-alpine AS build
WORKDIR /app

# Install all deps (including dev) for Tailwind build
COPY package*.json ./
RUN npm ci --no-audit --no-fund

# Copy source
COPY . .

# Compile Tailwind CSS to public/css/tailwind.css
RUN npm run build:css

# Drop dev deps to keep node_modules small for the runtime stage
RUN npm prune --omit=dev


# ---------- Stage 2: runtime ----------
FROM node:20-alpine AS runtime
WORKDIR /app

# Tini for proper PID 1 signal handling, curl for HEALTHCHECK
RUN apk add --no-cache tini curl \
    && addgroup -S pelxa && adduser -S pelxa -G pelxa

ENV NODE_ENV=production \
    PORT=3000

# Copy only what's needed at runtime
COPY --from=build --chown=pelxa:pelxa /app/node_modules ./node_modules
COPY --from=build --chown=pelxa:pelxa /app/app.js          ./app.js
COPY --from=build --chown=pelxa:pelxa /app/package.json    ./package.json
COPY --from=build --chown=pelxa:pelxa /app/controllers     ./controllers
COPY --from=build --chown=pelxa:pelxa /app/routes          ./routes
COPY --from=build --chown=pelxa:pelxa /app/middleware      ./middleware
COPY --from=build --chown=pelxa:pelxa /app/views           ./views
COPY --from=build --chown=pelxa:pelxa /app/data            ./data
COPY --from=build --chown=pelxa:pelxa /app/locales         ./locales
COPY --from=build --chown=pelxa:pelxa /app/public          ./public

USER pelxa

EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=3s --start-period=15s --retries=3 \
  CMD curl -fsS http://127.0.0.1:3000/healthz || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "app.js"]
