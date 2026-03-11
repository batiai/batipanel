#!/usr/bin/env bash
# batipanel server healthcheck
set -euo pipefail

GATEWAY_PORT="${BATIPANEL_GATEWAY_PORT:-18789}"

if curl -fsS "http://localhost:${GATEWAY_PORT}/healthz" >/dev/null 2>&1; then
  echo "healthy"
  exit 0
else
  echo "unhealthy"
  exit 1
fi
