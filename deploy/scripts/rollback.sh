#!/usr/bin/env bash
# =========================================================================
# Pelxa — Rollback to the previous color
#
# Useful if the new deploy passed health checks but you discover a problem
# minutes later. As long as the OLD color image is still on the host, this
# script can flip traffic back without rebuilding anything.
# =========================================================================
set -euo pipefail
cd "$(cd "$(dirname "$0")/../.." && pwd)"

ACTIVE_FILE="deploy/nginx/active/upstream.conf"

if grep -q "pelxa_blue:3000" "$ACTIVE_FILE"; then
  CURRENT="blue"; OTHER="green"
else
  CURRENT="green"; OTHER="blue"
fi

echo "[rollback] active=$CURRENT  rolling back to=$OTHER"

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
    server pelxa_${OTHER}:3000 max_fails=2 fail_timeout=5s;
    keepalive 16;
}
EOF
mv "$TMP" "$ACTIVE_FILE"

docker compose exec -T nginx nginx -t
docker compose exec -T nginx nginx -s reload

sleep 5
docker compose --profile "$CURRENT" stop "pelxa_${CURRENT}" || true
docker compose --profile "$CURRENT" rm -f "pelxa_${CURRENT}" || true

echo "[rollback] done — active=${OTHER}"
