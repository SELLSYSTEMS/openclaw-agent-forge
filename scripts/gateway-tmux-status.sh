#!/usr/bin/env bash
set -euo pipefail

SESSION_NAME="${OPENCLAW_TMUX_SESSION:-openclaw-gateway}"

if tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
  echo "tmux session ${SESSION_NAME} is running"
  tmux capture-pane -pt "${SESSION_NAME}" | tail -n 40
else
  echo "tmux session ${SESSION_NAME} is not running"
  exit 1
fi
