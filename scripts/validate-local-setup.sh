#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCHER="${ROOT}/bin/openclaw-local"
EXPECTED_WORKSPACE="${ROOT}/workspace"
EXPECTED_GATEWAY_MODE="local"
EXPECTED_GATEWAY_BIND="loopback"
BASELINE_MODEL="gpt-5.4"
EXPECTED_REASONING="xhigh"
SHARED_CODEX_CONFIG="${CODEX_CONFIG:-${HOME}/.codex/config.toml}"
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

resolve_expected_model() {
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
  if [[ ! -f "${SHARED_CODEX_CONFIG}" ]]; then
    return 1
  fi
  extract_toml_string model_reasoning_effort "${SHARED_CODEX_CONFIG}"
}

EXPECTED_MODEL="$(resolve_expected_model)"

"${LAUNCHER}" --version
env OPENCLAW_HOME="${ROOT}/.openclaw-home" "${ROOT}/.openclaw/bin/openclaw" config validate

for required_file in "${REQUIRED_WORKSPACE_CONTEXT[@]}"; do
  if [[ ! -f "${required_file}" ]]; then
    echo "Missing required seeded workspace context file: ${required_file}" >&2
    exit 1
  fi
done

actual_workspace="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.workspace
)"

if [[ "${actual_workspace}" != "${EXPECTED_WORKSPACE}" ]]; then
  echo "Workspace mismatch: expected ${EXPECTED_WORKSPACE}, got ${actual_workspace}" >&2
  exit 1
fi

actual_model="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.model.primary
)"

if [[ "${actual_model}" != "${EXPECTED_MODEL}" ]]; then
  echo "Model mismatch: expected ${EXPECTED_MODEL}, got ${actual_model}" >&2
  exit 1
fi

actual_gateway_mode="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get gateway.mode
)"

if [[ "${actual_gateway_mode}" != "${EXPECTED_GATEWAY_MODE}" ]]; then
  echo "Gateway mode mismatch: expected ${EXPECTED_GATEWAY_MODE}, got ${actual_gateway_mode}" >&2
  exit 1
fi

actual_gateway_bind="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get gateway.bind
)"

if [[ "${actual_gateway_bind}" != "${EXPECTED_GATEWAY_BIND}" ]]; then
  echo "Gateway bind mismatch: expected ${EXPECTED_GATEWAY_BIND}, got ${actual_gateway_bind}" >&2
  exit 1
fi

codex login status >/dev/null

actual_reasoning="$(resolve_shared_reasoning || true)"
if [[ "${actual_reasoning}" != "${EXPECTED_REASONING}" ]]; then
  echo "Shared Codex reasoning mismatch: expected ${EXPECTED_REASONING}, got ${actual_reasoning:-<unset>}" >&2
  exit 1
fi

echo "Local setup validated."
