#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SESSION_NAME="${OPENCLAW_TMUX_SESSION:-openclaw-gateway}"
LOG_DIR="${ROOT}/run"
LOG_FILE="${LOG_DIR}/gateway.log"

mkdir -p "${LOG_DIR}"

if tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
  echo "tmux session ${SESSION_NAME} already exists"
  exit 0
fi

tmux new-session -d -s "${SESSION_NAME}" \
  "cd ${ROOT} && env OPENCLAW_HOME=${ROOT}/.openclaw-home ${ROOT}/.openclaw/bin/openclaw gateway run --verbose | tee -a ${LOG_FILE}"

echo "Started OpenClaw gateway in tmux session: ${SESSION_NAME}"
echo "Logs: ${LOG_FILE}"
