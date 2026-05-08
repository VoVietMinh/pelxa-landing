#!/usr/bin/env bash
# =========================================================================
# Pelxa — Zero-downtime Blue/Green deploy
#
# What this script does, in order:
#   1. git pull origin main
#   2. Read which color (blue|green) is currently serving traffic
#   3. Build a fresh image (pelxa-app:latest) from the new code
#   4. Start the STANDBY color container, attached to the same network
#   5. Wait until the standby reports healthy on /healthz
#   6. Atomically swap nginx active upstream → standby color, reload nginx
#   7. Stop the OLD color container
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

ACTIVE_FILE="deploy/nginx/active/upstream.conf"
LOG_PREFIX="[pelxa-deploy]"

log() { echo "$LOG_PREFIX $*"; }
fail() { echo "$LOG_PREFIX ERROR: $*" >&2; exit 1; }

# ---------- 0. Sanity ----------
command -v docker >/dev/null || fail "docker not found"
docker compose version >/dev/null 2>&1 || fail "docker compose v2 not found"
[ -f "$ACTIVE_FILE" ] || fail "$ACTIVE_FILE missing"

# ---------- 1. Pull ----------
if [[ "${1:-}" != "--no-pull" ]]; then
  log "git pull origin main"
  git pull --ff-only origin main
fi

# ---------- 2. Detect colors ----------
if grep -q "pelxa_blue:3000" "$ACTIVE_FILE"; then
  CURRENT="blue"; NEXT="green"
elif grep -q "pelxa_green:3000" "$ACTIVE_FILE"; then
  CURRENT="green"; NEXT="blue"
else
  fail "could not detect active color in $ACTIVE_FILE"
fi
log "current=$CURRENT  next=$NEXT"

# ---------- 3. Build new image ----------
log "building image pelxa-app:latest"
docker compose build pelxa_blue   # builds the shared image used by both colors

# ---------- 4. Start standby ----------
log "starting standby container pelxa_${NEXT}"
docker compose --profile "$NEXT" up -d --no-deps "pelxa_${NEXT}"

# ---------- 5. Wait for standby to be healthy ----------
log "waiting for pelxa_${NEXT} to become healthy"
for i in $(seq 1 30); do
  status="$(docker inspect -f '{{.State.Health.Status}}' "pelxa_${NEXT}" 2>/dev/null || echo "unknown")"
  if [ "$status" = "healthy" ]; then
    log "pelxa_${NEXT} is healthy after ${i}s"
    break
  fi
  if [ "$i" = "30" ]; then
    log "pelxa_${NEXT} did NOT become healthy — aborting, keeping $CURRENT live"
    docker compose --profile "$NEXT" stop "pelxa_${NEXT}" || true
    docker compose --profile "$NEXT" rm -f "pelxa_${NEXT}" || true
    exit 1
  fi
  sleep 2
done

# ---------- 6. Atomic upstream swap + nginx reload ----------
log "swapping nginx upstream → pelxa_${NEXT}"
TMP="$(mktemp)"
cat > "$TMP" <<EOF
# Active upstream — DO NOT EDIT BY HAND.
# This file is rewritten atomically by deploy/scripts/deploy.sh.
upstream pelxa_active {
    server pelxa_${NEXT}:3000 max_fails=2 fail_timeout=5s;
    keepalive 16;
}
EOF
mv "$TMP" "$ACTIVE_FILE"

# Validate then reload (graceful — existing connections finish on old workers)
docker compose exec -T nginx nginx -t
docker compose exec -T nginx nginx -s reload
log "nginx reloaded — traffic now on pelxa_${NEXT}"

# ---------- 7. Drain & stop old color ----------
log "draining + stopping pelxa_${CURRENT}"
sleep 5   # let in-flight requests finish on the old upstream
docker compose --profile "$CURRENT" stop "pelxa_${CURRENT}" || true
# We keep the container removable so the next deploy can recreate it cleanly.
docker compose --profile "$CURRENT" rm -f "pelxa_${CURRENT}" || true

# ---------- 8. Cleanup dangling images ----------
docker image prune -f >/dev/null || true

log "deploy complete — active=${NEXT}"
