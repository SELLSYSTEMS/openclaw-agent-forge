#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UNIT_NAME="openclaw-gateway.service"
UNIT_SOURCE="${ROOT}/systemd/${UNIT_NAME}"
UNIT_TARGET="/etc/systemd/system/${UNIT_NAME}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root so the systemd unit can be installed under /etc/systemd/system." >&2
  exit 1
fi

if [[ ! -f "${UNIT_SOURCE}" ]]; then
  echo "Missing unit file: ${UNIT_SOURCE}" >&2
  exit 1
fi

install -m 0644 "${UNIT_SOURCE}" "${UNIT_TARGET}"
systemctl daemon-reload

if tmux has-session -t "${OPENCLAW_TMUX_SESSION:-openclaw-gateway}" 2>/dev/null; then
  "${ROOT}/scripts/stop-gateway-tmux.sh"
fi

systemctl enable --now "${UNIT_NAME}"

echo "Installed and enabled ${UNIT_NAME}"
echo "Check status with: ${ROOT}/scripts/gateway-systemd-status.sh"
echo "Logs: journalctl -u ${UNIT_NAME} -f"
