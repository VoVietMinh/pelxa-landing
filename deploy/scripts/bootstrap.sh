#!/usr/bin/env bash
# =========================================================================
# Pelxa — First-time production bootstrap (host nginx variant).
#
# Run ONCE on a fresh server, after `git clone`. Subsequent deploys use
# deploy.sh.
#
# What this does:
#   1. Install nginx natively if not present
#   2. Copy repo nginx configs to /etc/nginx/conf.d/
#   3. Disable the default nginx welcome site
#   4. nginx -t  +  systemctl reload nginx
#   5. docker compose build  +  start pelxa_blue on 127.0.0.1:5001
#   6. Verify /healthz via host nginx :80
# =========================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

log() { echo "[bootstrap] $*"; }
fail() { echo "[bootstrap] ERROR: $*" >&2; exit 1; }

# ---------- 1. Install nginx ----------
if ! command -v nginx >/dev/null 2>&1; then
  log "installing nginx"
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx
fi

# ---------- 2. Sync nginx configs from repo ----------
log "syncing nginx configs to /etc/nginx/conf.d/"
install -m 0644 deploy/nginx-host/00-cloudflare-realip.conf  /etc/nginx/conf.d/00-cloudflare-realip.conf
install -m 0644 deploy/nginx-host/01-pelxa-upstream.conf     /etc/nginx/conf.d/01-pelxa-upstream.conf
install -m 0644 deploy/nginx-host/10-pelxa.conf              /etc/nginx/conf.d/10-pelxa.conf

# Disable Ubuntu's default site (the "Welcome to nginx!" page)
if [ -L /etc/nginx/sites-enabled/default ]; then
  log "disabling Ubuntu default site"
  rm -f /etc/nginx/sites-enabled/default
fi

# ---------- 3. Validate + reload nginx ----------
log "nginx -t"
nginx -t

log "starting/reloading nginx"
systemctl enable --now nginx >/dev/null 2>&1 || true
systemctl reload nginx || systemctl restart nginx

# ---------- 4. Build app image + start blue ----------
log "building image pelxa-app:latest"
docker compose build pelxa_blue

log "starting pelxa_blue (active color, 127.0.0.1:5001)"
docker compose up -d pelxa_blue

log "waiting for pelxa_blue to become healthy"
for i in $(seq 1 30); do
  s="$(docker inspect -f '{{.State.Health.Status}}' pelxa_blue 2>/dev/null || echo unknown)"
  if [ "$s" = "healthy" ]; then
    log "pelxa_blue is healthy after ${i}s"
    break
  fi
  if [ "$i" = "30" ]; then
    fail "pelxa_blue did NOT become healthy"
  fi
  sleep 2
done

# ---------- 5. Verify ----------
log "verifying app via host nginx :80"
curl -fsS http://127.0.0.1/healthz && echo

log "DONE — active color = blue (127.0.0.1:5001)"
log "Next: point pelxa.com DNS at this server's IP (Cloudflare proxied)."
