#!/usr/bin/env bash
# =========================================================================
# Pelxa — Zero-downtime Blue/Green deploy (host nginx variant)
#
# Active-port marker file: /etc/nginx/conf.d/01-pelxa-upstream.conf
#   - blue  → server 127.0.0.1:5001
#   - green → server 127.0.0.1:5002
#
# Steps:
#   1. git pull origin main
#   2. Read which color/port is currently serving traffic
#   3. Build a fresh image (pelxa-app:latest) from the new code
#   4. Start the STANDBY color container (other port)
#   5. Wait until standby reports healthy on /healthz
#   6. Atomically rewrite /etc/nginx/conf.d/01-pelxa-upstream.conf
#   7. nginx -t and nginx -s reload  (graceful, zero-downtime)
#   8. Drain + stop OLD color container
#
# If anything fails before the swap, the old color keeps serving traffic.
# Run on the production server, in the project root.
#
# Usage:
#   ./deploy/scripts/deploy.sh           # normal deploy
#   ./deploy/scripts/deploy.sh --no-pull # skip git pull (deploy local code)
# =========================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

UPSTREAM_FILE="/etc/nginx/conf.d/01-pelxa-upstream.conf"
BLUE_PORT=5001
GREEN_PORT=5002

log() { echo "[deploy] $*"; }
fail() { echo "[deploy] ERROR: $*" >&2; exit 1; }

# ---------- 0. Sanity ----------
command -v docker  >/dev/null || fail "docker not found"
command -v nginx   >/dev/null || fail "nginx not installed on host"
docker compose version >/dev/null 2>&1 || fail "docker compose v2 not found"
[ -f "$UPSTREAM_FILE" ] || fail "$UPSTREAM_FILE missing — run bootstrap.sh first"

# ---------- 1. Pull ----------
if [ "${1:-}" != "--no-pull" ]; then
  log "git pull origin main"
  git pull --ff-only origin main
fi

# Re-sync the static nginx files in case they changed in this commit
log "syncing nginx static configs"
install -m 0644 deploy/nginx-host/00-cloudflare-realip.conf  /etc/nginx/conf.d/00-cloudflare-realip.conf
install -m 0644 deploy/nginx-host/10-pelxa.conf              /etc/nginx/conf.d/10-pelxa.conf

# ---------- 2. Detect colors ----------
if grep -q "127.0.0.1:${BLUE_PORT}" "$UPSTREAM_FILE"; then
  CURRENT="blue";  CURRENT_PORT=$BLUE_PORT
  NEXT="green";    NEXT_PORT=$GREEN_PORT
elif grep -q "127.0.0.1:${GREEN_PORT}" "$UPSTREAM_FILE"; then
  CURRENT="green"; CURRENT_PORT=$GREEN_PORT
  NEXT="blue";     NEXT_PORT=$BLUE_PORT
else
  fail "could not detect active color/port in $UPSTREAM_FILE"
fi
log "current=${CURRENT}:${CURRENT_PORT}  next=${NEXT}:${NEXT_PORT}"

# ---------- 3. Build new image ----------
log "building image pelxa-app:latest"
docker compose build pelxa_blue   # builds the shared image used by both colors

# ---------- 4. Start standby ----------
log "starting standby container pelxa_${NEXT} on 127.0.0.1:${NEXT_PORT}"
docker compose --profile "$NEXT" up -d --no-deps "pelxa_${NEXT}"

# ---------- 5. Wait for standby to be healthy ----------
log "waiting for pelxa_${NEXT} to become healthy"
for i in $(seq 1 30); do
  status="$(docker inspect -f '{{.State.Health.Status}}' "pelxa_${NEXT}" 2>/dev/null || echo unknown)"
  if [ "$status" = "healthy" ]; then
    log "pelxa_${NEXT} is healthy after ${i}s"
    break
  fi
  if [ "$i" = "30" ]; then
    log "pelxa_${NEXT} did NOT become healthy — aborting, keeping ${CURRENT} live"
    docker compose --profile "$NEXT" stop "pelxa_${NEXT}" || true
    docker compose --profile "$NEXT" rm -f "pelxa_${NEXT}" || true
    exit 1
  fi
  sleep 2
done

# Extra: hit the standby through its host port to make sure nginx will see it
log "sanity check: curl http://127.0.0.1:${NEXT_PORT}/healthz"
curl -fsS "http://127.0.0.1:${NEXT_PORT}/healthz" >/dev/null \
  || fail "standby /healthz not reachable on 127.0.0.1:${NEXT_PORT}"

# ---------- 6. Atomic upstream swap + nginx reload ----------
log "swapping nginx upstream to 127.0.0.1:${NEXT_PORT}"
TMP="$(mktemp)"
cat > "$TMP" <<EOF
# Active upstream — DO NOT EDIT BY HAND.
# Rewritten atomically by deploy/scripts/deploy.sh.
upstream pelxa_active {
    server 127.0.0.1:${NEXT_PORT} max_fails=2 fail_timeout=5s;
    keepalive 16;
}
EOF
mv "$TMP" "$UPSTREAM_FILE"

# Validate then graceful reload (existing connections finish on old workers)
nginx -t
nginx -s reload
log "nginx reloaded — public traffic now on pelxa_${NEXT}"

# ---------- 7. Drain & stop old color ----------
log "draining + stopping pelxa_${CURRENT}"
sleep 5   # let in-flight requests finish on the old upstream
docker compose --profile "$CURRENT" stop "pelxa_${CURRENT}" || true
docker compose --profile "$CURRENT" rm -f "pelxa_${CURRENT}" || true

# ---------- 8. Cleanup dangling images ----------
docker image prune -f >/dev/null || true

log "deploy complete — active=${NEXT}:${NEXT_PORT}"
