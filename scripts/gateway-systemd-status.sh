#!/usr/bin/env bash
set -euo pipefail

UNIT_NAME="openclaw-gateway.service"

echo "[enabled]"
systemctl is-enabled "${UNIT_NAME}" 2>/dev/null || true
echo

echo "[active]"
systemctl is-active "${UNIT_NAME}" 2>/dev/null || true
echo

echo "[status]"
systemctl --no-pager --full status "${UNIT_NAME}" | sed -n '1,80p'
