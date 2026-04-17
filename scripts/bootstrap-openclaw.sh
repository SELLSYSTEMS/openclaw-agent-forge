#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFIX="${ROOT}/.openclaw"
OPENCLAW_HOME_DIR="${ROOT}/.openclaw-home"
WORKSPACE_DIR="${ROOT}/workspace"
MEMORY_DIR="${ROOT}/memory"
SHARED_CODEX_CONFIG="${CODEX_CONFIG:-${HOME}/.codex/config.toml}"
BASELINE_MODEL="gpt-5.4"
BASELINE_REASONING="xhigh"
REQUIRED_WORKSPACE_CONTEXT=(
  "${ROOT}/workspace/AGENTS.md"
  "${ROOT}/workspace/MEMORY.md"
  "${ROOT}/workspace/TOOLS.md"
  "${ROOT}/workspace/WEBTERMINAL.md"
  "${ROOT}/workspace/SOUL.md"
  "${ROOT}/workspace/IDENTITY.md"
  "${ROOT}/workspace/USER.md"
)

extract_toml_string() {
  local key="$1"
  local file="$2"
  awk -F'"' -v key="${key}" '$0 ~ "^[[:space:]]*" key " = \"" { print $2; exit }' "${file}"
}

model_is_newer_than_baseline() {
  local model="$1"
  if [[ "${model}" =~ ^gpt-([0-9]+)(\.([0-9]+))?([.-].*)?$ ]]; then
    local major="${BASH_REMATCH[1]}"
    local minor="${BASH_REMATCH[3]:-0}"
    (( major > 5 || (major == 5 && minor > 4) ))
    return
  fi
  return 1
}

resolve_openclaw_primary_model() {
  local shared_model=""
  if [[ -f "${SHARED_CODEX_CONFIG}" ]]; then
    shared_model="$(extract_toml_string model "${SHARED_CODEX_CONFIG}" || true)"
  fi

  if [[ -n "${shared_model}" ]] && model_is_newer_than_baseline "${shared_model}"; then
    printf 'codex-cli/%s\n' "${shared_model}"
    return
  fi

  printf 'codex-cli/%s\n' "${BASELINE_MODEL}"
}

resolve_shared_reasoning() {
  local shared_reasoning=""
  if [[ -f "${SHARED_CODEX_CONFIG}" ]]; then
    shared_reasoning="$(extract_toml_string model_reasoning_effort "${SHARED_CODEX_CONFIG}" || true)"
  fi

  if [[ -n "${shared_reasoning}" ]]; then
    printf '%s\n' "${shared_reasoning}"
    return
  fi

  printf '%s\n' "${BASELINE_REASONING}"
}

mkdir -p "${OPENCLAW_HOME_DIR}" "${WORKSPACE_DIR}" "${MEMORY_DIR}/inbox" "${MEMORY_DIR}/projects" "${MEMORY_DIR}/references" "${ROOT}/bin"

for required_file in "${REQUIRED_WORKSPACE_CONTEXT[@]}"; do
  if [[ ! -f "${required_file}" ]]; then
    echo "Missing required seeded workspace context file: ${required_file}" >&2
    echo "Restore the tracked workspace context before bootstrap continues." >&2
    exit 1
  fi
done

if [[ ! -x "${PREFIX}/bin/openclaw" ]]; then
  curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install-cli.sh | bash -s -- --prefix "${PREFIX}" --no-onboard
fi

TARGET_PRIMARY_MODEL="$(resolve_openclaw_primary_model)"

env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.workspace "${WORKSPACE_DIR}"
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" models set "${TARGET_PRIMARY_MODEL}"
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
  echo "Install/login Codex CLI before using Codex-backed OpenClaw turns."
fi

echo "Selected OpenClaw primary model: ${TARGET_PRIMARY_MODEL}"
if [[ "$(resolve_shared_reasoning)" != "${BASELINE_REASONING}" ]]; then
  echo "Warning: shared Codex reasoning is not ${BASELINE_REASONING}. OpenClaw is expected to run with ${BASELINE_REASONING} reasoning on this host." >&2
fi

echo "Bootstrap complete."
echo "Run: ${ROOT}/bin/openclaw-local"
