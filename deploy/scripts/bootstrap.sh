#!/usr/bin/env bash
# =========================================================================
# Pelxa — First-time production bootstrap.
#
# Run ONCE on a fresh server, after `git clone`. Subsequent deploys use
# deploy.sh.
# =========================================================================
set -euo pipefail
cd "$(cd "$(dirname "$0")/../.." && pwd)"

echo "[bootstrap] building image"
docker compose build pelxa_blue

echo "[bootstrap] starting nginx + pelxa_blue (active color)"
docker compose up -d nginx pelxa_blue

echo "[bootstrap] waiting for pelxa_blue to be healthy"
for i in $(seq 1 30); do
  s="$(docker inspect -f '{{.State.Health.Status}}' pelxa_blue 2>/dev/null || echo unknown)"
  [ "$s" = "healthy" ] && { echo "[bootstrap] healthy after ${i}s"; break; }
  sleep 2
done

echo "[bootstrap] verifying public health endpoint"
curl -fsS http://127.0.0.1/healthz && echo

echo "[bootstrap] done. Active color = blue"
