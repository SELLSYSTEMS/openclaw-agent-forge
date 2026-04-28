#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UNIT_NAME="openclaw-gateway.service"
UNIT_SOURCE="${ROOT}/systemd/${UNIT_NAME}"
UNIT_TARGET="/etc/systemd/system/${UNIT_NAME}"
ENV_FILE="${ROOT}/.openclaw-home/openclaw-gateway.env"

hostname_has_long_dns_label() {
  local host_value
  host_value="$(hostname -f 2>/dev/null || hostname)"
  IFS='.' read -r -a labels <<< "${host_value}"
  local label
  for label in "${labels[@]}"; do
    if (( ${#label} > 63 )); then
      return 0
    fi
  done
  return 1
}

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root so the systemd unit can be installed under /etc/systemd/system." >&2
  exit 1
fi

if [[ ! -f "${UNIT_SOURCE}" ]]; then
  echo "Missing unit file: ${UNIT_SOURCE}" >&2
  exit 1
fi

mkdir -p "$(dirname "${ENV_FILE}")"

if hostname_has_long_dns_label; then
  if [[ ! -f "${ENV_FILE}" ]] || ! grep -q '^OPENCLAW_DISABLE_BONJOUR=' "${ENV_FILE}" 2>/dev/null; then
    {
      [[ -f "${ENV_FILE}" ]] && cat "${ENV_FILE}"
      echo "OPENCLAW_DISABLE_BONJOUR=1"
    } | awk '!seen[$0]++' > "${ENV_FILE}.tmp"
    mv "${ENV_FILE}.tmp" "${ENV_FILE}"
    chmod 600 "${ENV_FILE}"
  fi
fi

sed "s|__ROOT__|${ROOT}|g" "${UNIT_SOURCE}" > "${UNIT_TARGET}"
chmod 0644 "${UNIT_TARGET}"
systemctl daemon-reload

if tmux has-session -t "${OPENCLAW_TMUX_SESSION:-openclaw-gateway}" 2>/dev/null; then
  "${ROOT}/scripts/stop-gateway-tmux.sh"
fi

systemctl enable --now "${UNIT_NAME}"

echo "Installed and enabled ${UNIT_NAME}"
echo "Check status with: ${ROOT}/scripts/gateway-systemd-status.sh"
echo "Logs: journalctl -u ${UNIT_NAME} -f"
