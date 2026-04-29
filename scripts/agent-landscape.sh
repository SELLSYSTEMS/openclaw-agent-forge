#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_DIR="${ROOT}/workspace"
OPENCLAW_HOME_DIR="${ROOT}/.openclaw-home"
LAUNCHER="${ROOT}/bin/openclaw-local"

echo "== Shared Host Context =="
echo

if [[ -d /root/.codex ]]; then
  echo "[codex]"
  echo "home: /root/.codex"
  if [[ -f /root/.codex/config.toml ]]; then
    echo "global defaults:"
    rg -n '^(model|model_reasoning_effort|approval_policy|sandbox_mode)\s*=' /root/.codex/config.toml || true
    echo "trusted project roots:"
    rg -n '^\[projects\.' /root/.codex/config.toml || true
  fi
  [[ -f /root/.codex/history.jsonl ]] && echo "history: /root/.codex/history.jsonl"
  [[ -f /root/.codex/logs_2.sqlite ]] && echo "logs db: /root/.codex/logs_2.sqlite"
  [[ -f /root/.codex/state_5.sqlite ]] && echo "state db: /root/.codex/state_5.sqlite"
  echo
fi

if [[ -d /root/.node-red ]]; then
  echo "[node-red]"
  echo "home: /root/.node-red"
  [[ -f /root/.node-red/flows.json ]] && echo "flows: /root/.node-red/flows.json"
  [[ -f /root/.node-red/package.json ]] && echo "package: /root/.node-red/package.json"
  if [[ -f /root/.node-red/settings.js ]]; then
    flow_file="$(sed -n "s/.*flowFile: '\\([^']*\\)'.*/\\1/p" /root/.node-red/settings.js | head -n1)"
    ui_port="$(sed -n 's/.*uiPort: process.env.PORT || \([0-9][0-9]*\).*/\1/p' /root/.node-red/settings.js | head -n1)"
    [[ -n "${flow_file}" ]] && echo "configured flow file: ${flow_file}"
    [[ -n "${ui_port}" ]] && echo "ui port default: ${ui_port}"
    if rg -q 'flowFilePretty:\s*true' /root/.node-red/settings.js; then
      echo "flowFilePretty: true"
    fi
    if rg -q 'adminAuth:' /root/.node-red/settings.js; then
      echo "adminAuth: configured"
    fi
    if rg -q 'projects:' /root/.node-red/settings.js; then
      echo "projects support: configured"
    fi
  fi
  echo
fi

if [[ -f /opt/claude-vnc-terminal/data/terminal-state.json ]]; then
  echo "[webterminal-tabs]"
  echo "implementation: /opt/claude-vnc-terminal"
  echo "state file: /opt/claude-vnc-terminal/data/terminal-state.json"
  jq -r '
    .terminals[]?
    | "- " + (.name // "unnamed") + " | cwd=" + (.cwd // "?") + " | provider=" + (.provider // "?")
  ' /opt/claude-vnc-terminal/data/terminal-state.json 2>/dev/null || echo "failed to parse terminal-state.json"
  echo
fi

echo "[observed-workspaces]"
echo "${ROOT} -> OpenClaw (current repo root)"
if [[ -f /opt/claude-vnc-terminal/data/terminal-state.json ]]; then
  jq -r '
    .terminals[]?
    | select(.cwd != null and .cwd != "")
    | .cwd + " -> tab:" + (.name // "unnamed") + " provider=" + (.provider // "?")
  ' /opt/claude-vnc-terminal/data/terminal-state.json 2>/dev/null | awk '!seen[$0]++' || true
fi
if [[ -f "${WORKSPACE_DIR}/WEBTERMINAL.local.md" ]]; then
  echo "webterminal note: ${WORKSPACE_DIR}/WEBTERMINAL.local.md"
fi
echo

echo "[openclaw]"
if [[ -x "${LAUNCHER}" ]]; then
  echo "repo: ${ROOT}"
  echo "launcher: ${LAUNCHER}"
  env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${LAUNCHER}" health || true
else
  echo "OpenClaw launcher not found"
fi
echo

echo "[openclaw-systemd]"
if systemctl is-enabled openclaw-gateway.service >/dev/null 2>&1; then
  echo "enabled: $(systemctl is-enabled openclaw-gateway.service)"
else
  echo "enabled: not-installed-or-disabled"
fi
if systemctl is-active openclaw-gateway.service >/dev/null 2>&1; then
  echo "active: $(systemctl is-active openclaw-gateway.service)"
else
  echo "active: inactive-or-missing"
fi
echo

echo "[processes]"
ps -ef | rg -i 'node-red|openclaw|/usr/bin/codex|codex/codex|tmux' || true
echo

echo "[tmux]"
tmux ls 2>/dev/null || echo "no tmux sessions"
