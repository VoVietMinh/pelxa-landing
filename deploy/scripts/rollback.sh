#!/usr/bin/env bash
# =========================================================================
# Pelxa — Rollback to the previous color (host nginx variant)
#
# Useful if a deploy passed health checks but you discover a problem later.
# As long as the OLD color image is still on the host, this brings the
# previous color up using the cached image and flips traffic back.
# =========================================================================
set -euo pipefail
cd "$(cd "$(dirname "$0")/../.." && pwd)"

UPSTREAM_FILE="/etc/nginx/conf.d/01-pelxa-upstream.conf"
BLUE_PORT=5001
GREEN_PORT=5002

if grep -q "127.0.0.1:${BLUE_PORT}" "$UPSTREAM_FILE"; then
  CURRENT="blue";  CURRENT_PORT=$BLUE_PORT
  OTHER="green";   OTHER_PORT=$GREEN_PORT
else
  CURRENT="green"; CURRENT_PORT=$GREEN_PORT
  OTHER="blue";    OTHER_PORT=$BLUE_PORT
fi

echo "[rollback] active=${CURRENT}:${CURRENT_PORT}  rolling back to=${OTHER}:${OTHER_PORT}"

# Start the other color from the existing image
docker compose --profile "$OTHER" up -d --no-deps "pelxa_${OTHER}"

# Wait briefly for health
for i in $(seq 1 15); do
  s="$(docker inspect -f '{{.State.Health.Status}}' "pelxa_${OTHER}" 2>/dev/null || echo unknown)"
  [ "$s" = "healthy" ] && break
  sleep 2
done

# Swap upstream
TMP="$(mktemp)"
cat > "$TMP" <<EOF
upstream pelxa_active {
    server 127.0.0.1:${OTHER_PORT} max_fails=2 fail_timeout=5s;
    keepalive 16;
}
EOF
mv "$TMP" "$UPSTREAM_FILE"

nginx -t
nginx -s reload

sleep 5
docker compose --profile "$CURRENT" stop "pelxa_${CURRENT}" || true
docker compose --profile "$CURRENT" rm -f "pelxa_${CURRENT}" || true

echo "[rollback] done — active=${OTHER}:${OTHER_PORT}"
