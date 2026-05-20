#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCHER="${ROOT}/bin/openclaw-local"
EXPECTED_WORKSPACE="${ROOT}/workspace"
EXPECTED_GATEWAY_MODE="local"
EXPECTED_GATEWAY_BIND="loopback"
BASELINE_MODEL="gpt-5.4"
EXPECTED_REASONING="xhigh"
EXPECTED_RUNTIME_ID="codex-cli"
EXPECTED_AGENT_TIMEOUT_SECONDS=604800
EXPECTED_LLM_IDLE_TIMEOUT_SECONDS=0
EXPECTED_CONTEXT_INJECTION="continuation-skip"
EXPECTED_SANDBOX_MODE="off"
EXPECTED_CLI_WATCHDOG_TIMEOUT_MS=604800000
EXPECTED_CODEX_CLI_ARGS_JSON='["exec","--json","--color","never","--dangerously-bypass-approvals-and-sandbox","--skip-git-repo-check"]'
EXPECTED_CODEX_CLI_RESUME_ARGS_JSON='["exec","resume","{sessionId}","--color","never","--dangerously-bypass-approvals-and-sandbox","--skip-git-repo-check"]'
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
    (( major > 5 || (major == 5 && minor > 5) ))
    return
  fi
  return 1
}

resolve_expected_base_model_name() {
  local shared_model=""
  if [[ -f "${SHARED_CODEX_CONFIG}" ]]; then
    shared_model="$(extract_toml_string model "${SHARED_CODEX_CONFIG}" || true)"
  fi

  if [[ -n "${shared_model}" ]] && model_is_newer_than_baseline "${shared_model}"; then
    printf '%s\n' "${shared_model}"
    return
  fi

  printf '%s\n' "${BASELINE_MODEL}"
}

resolve_shared_reasoning() {
  if [[ ! -f "${SHARED_CODEX_CONFIG}" ]]; then
    return 1
  fi
  extract_toml_string model_reasoning_effort "${SHARED_CODEX_CONFIG}"
}

compact_json() {
  tr -d '[:space:]'
}

EXPECTED_BASE_MODEL="$(resolve_expected_base_model_name)"
EXPECTED_LEGACY_MODEL="codex-cli/${EXPECTED_BASE_MODEL}"
EXPECTED_CANONICAL_MODEL="openai/${EXPECTED_BASE_MODEL}"
EXPECTED_CODEX_CLI_ARGS_COMPACT="$(printf '%s' "${EXPECTED_CODEX_CLI_ARGS_JSON}" | compact_json)"
EXPECTED_CODEX_CLI_RESUME_ARGS_COMPACT="$(printf '%s' "${EXPECTED_CODEX_CLI_RESUME_ARGS_JSON}" | compact_json)"

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

actual_runtime_id="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.agentRuntime.id 2>/dev/null || true
)"

model_ok=0
if [[ "${actual_model}" == "${EXPECTED_LEGACY_MODEL}" ]]; then
  model_ok=1
elif [[ "${actual_model}" == "${EXPECTED_CANONICAL_MODEL}" && "${actual_runtime_id}" == "${EXPECTED_RUNTIME_ID}" ]]; then
  model_ok=1
fi

if [[ "${model_ok}" -ne 1 ]]; then
  echo "Model/runtime mismatch: expected either ${EXPECTED_LEGACY_MODEL} or ${EXPECTED_CANONICAL_MODEL} with agentRuntime.id=${EXPECTED_RUNTIME_ID}, got model=${actual_model} runtime=${actual_runtime_id:-<unset>}" >&2
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

actual_agent_timeout_seconds="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.timeoutSeconds 2>/dev/null || true
)"

if [[ ! "${actual_agent_timeout_seconds}" =~ ^[0-9]+$ ]] || (( actual_agent_timeout_seconds < EXPECTED_AGENT_TIMEOUT_SECONDS )); then
  echo "Agent timeout mismatch: expected at least ${EXPECTED_AGENT_TIMEOUT_SECONDS}, got ${actual_agent_timeout_seconds:-<unset>}" >&2
  exit 1
fi

actual_llm_idle_timeout_seconds="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.llm.idleTimeoutSeconds 2>/dev/null || true
)"

if [[ "${actual_llm_idle_timeout_seconds}" != "${EXPECTED_LLM_IDLE_TIMEOUT_SECONDS}" ]]; then
  echo "LLM idle timeout mismatch: expected ${EXPECTED_LLM_IDLE_TIMEOUT_SECONDS}, got ${actual_llm_idle_timeout_seconds:-<unset>}" >&2
  exit 1
fi

actual_context_injection="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.contextInjection 2>/dev/null || true
)"

if [[ "${actual_context_injection}" != "${EXPECTED_CONTEXT_INJECTION}" ]]; then
  echo "Context injection mismatch: expected ${EXPECTED_CONTEXT_INJECTION}, got ${actual_context_injection:-<unset>}" >&2
  exit 1
fi

actual_sandbox_mode="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.sandbox.mode 2>/dev/null || true
)"

if [[ "${actual_sandbox_mode}" != "${EXPECTED_SANDBOX_MODE}" ]]; then
  echo "OpenClaw sandbox mode mismatch: expected ${EXPECTED_SANDBOX_MODE}, got ${actual_sandbox_mode:-<unset>}" >&2
  exit 1
fi

actual_codex_cli_args="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.cliBackends.codex-cli.args 2>/dev/null || true
)"

if [[ "$(printf '%s' "${actual_codex_cli_args}" | compact_json)" != "${EXPECTED_CODEX_CLI_ARGS_COMPACT}" ]]; then
  echo "Codex CLI args mismatch. The bundled OpenClaw default uses --sandbox workspace-write, which breaks this host class." >&2
  echo "Expected: ${EXPECTED_CODEX_CLI_ARGS_JSON}" >&2
  echo "Got: ${actual_codex_cli_args:-<unset>}" >&2
  exit 1
fi

actual_codex_cli_resume_args="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.cliBackends.codex-cli.resumeArgs 2>/dev/null || true
)"

if [[ "$(printf '%s' "${actual_codex_cli_resume_args}" | compact_json)" != "${EXPECTED_CODEX_CLI_RESUME_ARGS_COMPACT}" ]]; then
  echo "Codex CLI resume args mismatch. Resume runs must also bypass the Codex CLI sandbox on this host class." >&2
  echo "Expected: ${EXPECTED_CODEX_CLI_RESUME_ARGS_JSON}" >&2
  echo "Got: ${actual_codex_cli_resume_args:-<unset>}" >&2
  exit 1
fi

actual_watchdog_fresh_ms="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.cliBackends.codex-cli.reliability.watchdog.fresh.noOutputTimeoutMs 2>/dev/null || true
)"

if [[ ! "${actual_watchdog_fresh_ms}" =~ ^[0-9]+$ ]] || (( actual_watchdog_fresh_ms < EXPECTED_CLI_WATCHDOG_TIMEOUT_MS )); then
  echo "Codex CLI fresh watchdog mismatch: expected at least ${EXPECTED_CLI_WATCHDOG_TIMEOUT_MS}, got ${actual_watchdog_fresh_ms:-<unset>}" >&2
  exit 1
fi

actual_watchdog_resume_ms="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.cliBackends.codex-cli.reliability.watchdog.resume.noOutputTimeoutMs 2>/dev/null || true
)"

if [[ ! "${actual_watchdog_resume_ms}" =~ ^[0-9]+$ ]] || (( actual_watchdog_resume_ms < EXPECTED_CLI_WATCHDOG_TIMEOUT_MS )); then
  echo "Codex CLI resume watchdog mismatch: expected at least ${EXPECTED_CLI_WATCHDOG_TIMEOUT_MS}, got ${actual_watchdog_resume_ms:-<unset>}" >&2
  exit 1
fi

actual_telegram_enabled="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get channels.telegram.enabled 2>/dev/null || true
)"

if [[ "${actual_telegram_enabled}" == "true" ]]; then
  actual_telegram_exec_approvals="$(
    env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
      "${ROOT}/.openclaw/bin/openclaw" config get channels.telegram.execApprovals.enabled 2>/dev/null || true
  )"

  if [[ -z "${actual_telegram_exec_approvals}" || "${actual_telegram_exec_approvals}" == "auto" ]]; then
    echo "Telegram exec approvals must be explicitly configured on this host. Set channels.telegram.execApprovals.enabled=false for the stable default, or true only after intentional operator.approvals pairing." >&2
    exit 1
  fi
fi

codex login status >/dev/null

actual_reasoning="$(resolve_shared_reasoning || true)"
if [[ "${actual_reasoning}" != "${EXPECTED_REASONING}" ]]; then
  echo "Shared Codex reasoning mismatch: expected ${EXPECTED_REASONING}, got ${actual_reasoning:-<unset>}" >&2
  exit 1
fi

if [[ ! -x "${ROOT}/.venv-stt/bin/python" ]]; then
  echo "Missing repo-local STT venv: ${ROOT}/.venv-stt" >&2
  exit 1
fi

if ! "${ROOT}/.venv-stt/bin/python" -c 'import faster_whisper' >/dev/null 2>&1; then
  echo "Repo-local STT venv exists but faster-whisper is not importable." >&2
  exit 1
fi

"${ROOT}/scripts/validate-local-stt.sh" >/dev/null

echo "Local setup validated."
