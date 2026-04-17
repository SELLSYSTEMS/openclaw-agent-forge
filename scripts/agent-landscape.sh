#!/usr/bin/env bash
set -euo pipefail

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

echo "[known-workspaces]"
for entry in \
  "/home/admin:Default AI" \
  "/home/langchain:learnLangChain" \
  "/home/udacity:learnUdacity" \
  "/home/OpenClaw:OpenClaw"
do
  path="${entry%%:*}"
  label="${entry#*:}"
  if [[ -d "${path}" ]]; then
    echo "${path} -> ${label}"
  else
    echo "${path} -> ${label} (missing)"
  fi
done
if [[ -f /home/OpenClaw/workspace/WEBTERMINAL.local.md ]]; then
  echo "webterminal note: /home/OpenClaw/workspace/WEBTERMINAL.local.md"
fi
echo

echo "[openclaw]"
if [[ -x /home/OpenClaw/bin/openclaw-local ]]; then
  echo "repo: /home/OpenClaw"
  echo "launcher: /home/OpenClaw/bin/openclaw-local"
  env OPENCLAW_HOME=/home/OpenClaw/.openclaw-home /home/OpenClaw/bin/openclaw-local health || true
else
  echo "OpenClaw launcher not found"
fi
echo

echo "[processes]"
ps -ef | rg -i 'node-red|openclaw|/usr/bin/codex|codex/codex|tmux' || true
echo

echo "[tmux]"
tmux ls 2>/dev/null || echo "no tmux sessions"
