#!/usr/bin/env bash
set -euo pipefail

SESSION_NAME="${OPENCLAW_TMUX_SESSION:-openclaw-gateway}"

if ! tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
  echo "tmux session ${SESSION_NAME} is not running"
  exit 0
fi

tmux kill-session -t "${SESSION_NAME}"
echo "Stopped tmux session: ${SESSION_NAME}"
