#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFIX="${ROOT}/.openclaw"
OPENCLAW_HOME_DIR="${ROOT}/.openclaw-home"
WORKSPACE_DIR="${ROOT}/workspace"
MEMORY_DIR="${ROOT}/memory"

mkdir -p "${OPENCLAW_HOME_DIR}" "${WORKSPACE_DIR}" "${MEMORY_DIR}/inbox" "${MEMORY_DIR}/projects" "${MEMORY_DIR}/references" "${ROOT}/bin"

if [[ ! -x "${PREFIX}/bin/openclaw" ]]; then
  curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install-cli.sh | bash -s -- --prefix "${PREFIX}" --no-onboard
fi

env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.workspace "${WORKSPACE_DIR}"
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" models set codex-cli/gpt-5.4
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set gateway.mode local
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set gateway.bind loopback
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config validate

if command -v codex >/dev/null 2>&1; then
  if ! codex login status >/dev/null 2>&1; then
    echo "Codex CLI is installed but not authenticated yet."
    echo "Run: codex login"
  fi
else
  echo "Codex CLI is not installed or not on PATH."
  echo "Install/login Codex CLI before using codex-cli/gpt-5.4 turns."
fi

echo "Bootstrap complete."
echo "Run: ${ROOT}/bin/openclaw-local"
