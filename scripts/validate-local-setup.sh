#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCHER="${ROOT}/bin/openclaw-local"
EXPECTED_WORKSPACE="${ROOT}/workspace"
EXPECTED_GATEWAY_MODE="local"
EXPECTED_GATEWAY_BIND="loopback"
BASELINE_MODEL="gpt-5.4"
BASELINE_MODEL_REF="codex/gpt-5.4"
EXPECTED_REASONING="xhigh"
EXPECTED_THINKING_DEFAULT="xhigh"
EXPECTED_HARNESS_RUNTIME="codex"
EXPECTED_HARNESS_FALLBACK="pi"
EXPECTED_CODEX_APP_SERVER_APPROVAL_POLICY="never"
EXPECTED_CODEX_APP_SERVER_SANDBOX="danger-full-access"
EXPECTED_CODEX_APP_SERVER_TIMEOUT_MS=604800000
EXPECTED_AGENT_TIMEOUT_SECONDS=604800
EXPECTED_LLM_IDLE_TIMEOUT_SECONDS=0
EXPECTED_CONTEXT_INJECTION="continuation-skip"
EXPECTED_SANDBOX_MODE="off"
EXPECTED_CONTEXT_PRUNING_MODE="cache-ttl"
EXPECTED_CONTEXT_PRUNING_TTL="5m"
EXPECTED_SESSION_RESET_MODE="daily"
EXPECTED_SESSION_RESET_HOUR=4
EXPECTED_DIRECT_RESET_MODE="idle"
EXPECTED_DIRECT_RESET_IDLE_MINUTES=240
EXPECTED_CLI_WATCHDOG_TIMEOUT_MS=604800000
EXPECTED_CODEX_CLI_ARGS_JSON='["exec","--json","--color","never","--dangerously-bypass-approvals-and-sandbox","--skip-git-repo-check"]'
EXPECTED_CODEX_CLI_RESUME_ARGS_JSON='["exec","resume","--json","--dangerously-bypass-approvals-and-sandbox","--skip-git-repo-check","{sessionId}"]'
EXPECTED_CODEX_CLI_OUTPUT_MODE="jsonl"
EXPECTED_SYSTEMD_OOM_POLICY="continue"
CODEX_APP_SERVER_RECOVERY_MARKER="codex-app-server-recovery"
CODEX_APP_SERVER_RECOVERY_MARKER_V2="codex-app-server-recovery-v2"
TELEGRAM_OUTBOX_GENERIC_FAILURE_MARKER="telegram-durable-outbox-skip-generic-failures"
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

resolve_expected_base_model_name() {
  local requested_model="${OPENCLAW_EXPECTED_PRIMARY_MODEL:-${OPENCLAW_PRIMARY_MODEL:-${OPENCLAW_MODEL:-}}}"

  if [[ -n "${requested_model}" ]]; then
    if [[ "${requested_model}" == codex/* ]]; then
      printf '%s\n' "${requested_model#codex/}"
      return
    fi

    if [[ "${requested_model}" == gpt-* ]]; then
      printf '%s\n' "${requested_model}"
      return
    fi

    echo "Unsupported OPENCLAW_EXPECTED_PRIMARY_MODEL value: ${requested_model}" >&2
    echo "Use codex/gpt-5.4, codex/<validated-newer-model>, or a bare gpt-* model name." >&2
    exit 1
  fi

  printf '%s\n' "${BASELINE_MODEL}"
}

resolve_shared_model() {
  if [[ ! -f "${SHARED_CODEX_CONFIG}" ]]; then
    return 1
  fi
  extract_toml_string model "${SHARED_CODEX_CONFIG}"
}

emit_newer_model_note() {
  local shared_model=""
  shared_model="$(resolve_shared_model || true)"

  if [[ -n "${shared_model}" ]] && model_is_newer_than_baseline "${shared_model}" && [[ "${EXPECTED_PRIMARY_MODEL}" != "codex/${shared_model}" ]]; then
    echo "Note: shared Codex default is ${shared_model}; OpenClaw validation still expects ${EXPECTED_PRIMARY_MODEL} until a newer codex/<model> passes OpenClaw startup and smoke validation." >&2
    return
  fi
}

primary_model_is_allowed() {
  local actual_model="$1"
  local shared_model=""

  if [[ "${actual_model}" == "${EXPECTED_PRIMARY_MODEL}" ]]; then
    return 0
  fi

  shared_model="$(resolve_shared_model || true)"
  if [[ -n "${shared_model}" ]] && model_is_newer_than_baseline "${shared_model}" && [[ "${actual_model}" == "codex/${shared_model}" ]]; then
    return 0
  fi

  return 1
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
if [[ "${EXPECTED_BASE_MODEL}" == "${BASELINE_MODEL}" ]]; then
  EXPECTED_PRIMARY_MODEL="${BASELINE_MODEL_REF}"
else
  EXPECTED_PRIMARY_MODEL="codex/${EXPECTED_BASE_MODEL}"
fi
EXPECTED_CODEX_CLI_ARGS_COMPACT="$(printf '%s' "${EXPECTED_CODEX_CLI_ARGS_JSON}" | compact_json)"
EXPECTED_CODEX_CLI_RESUME_ARGS_COMPACT="$(printf '%s' "${EXPECTED_CODEX_CLI_RESUME_ARGS_JSON}" | compact_json)"

"${LAUNCHER}" --version
env OPENCLAW_HOME="${ROOT}/.openclaw-home" "${ROOT}/.openclaw/bin/openclaw" config validate
"${ROOT}/scripts/validate-codex-harness-contract.sh"
"${ROOT}/scripts/validate-codex-cli-contract.sh"

codex_runner_file="$(find "${ROOT}/.openclaw/lib/node_modules/openclaw/dist" -maxdepth 1 -name 'pi-embedded-runner-*.js' -print -quit)"
if [[ -z "${codex_runner_file}" || ! -f "${codex_runner_file}" ]]; then
  echo "Unable to find OpenClaw pi embedded runner for Codex app-server recovery validation." >&2
  exit 1
fi

if ! grep -q "${CODEX_APP_SERVER_RECOVERY_MARKER}" "${codex_runner_file}"; then
  echo "Missing Codex app-server recovery patch. Run scripts/apply-openclaw-runtime-patches.sh and restart openclaw-gateway.service." >&2
  exit 1
fi

if ! grep -q "${CODEX_APP_SERVER_RECOVERY_MARKER_V2}" "${codex_runner_file}"; then
  echo "Missing Codex app-server recovery patch v2. Run scripts/apply-openclaw-runtime-patches.sh and restart openclaw-gateway.service." >&2
  exit 1
fi

node --check "${codex_runner_file}" >/dev/null

telegram_bot_file="$(grep -l 'TELEGRAM_DURABLE_OUTBOX_RECOVERY_PREFIX' "${ROOT}/.openclaw/lib/node_modules/openclaw/dist"/bot-*.js 2>/dev/null | head -n 1 || true)"
if [[ -z "${telegram_bot_file}" || ! -f "${telegram_bot_file}" ]]; then
  echo "Unable to find OpenClaw Telegram bot runtime for durable outbox validation." >&2
  exit 1
fi

if ! grep -q "${TELEGRAM_OUTBOX_GENERIC_FAILURE_MARKER}" "${telegram_bot_file}"; then
  echo "Missing Telegram durable outbox generic-failure skip patch. Run scripts/apply-openclaw-runtime-patches.sh and restart openclaw-gateway.service." >&2
  exit 1
fi

if ! grep -q "shouldSkipTelegramDurableOutboxEntry" "${telegram_bot_file}"; then
  echo "Telegram durable outbox patch is incomplete: missing shouldSkipTelegramDurableOutboxEntry." >&2
  exit 1
fi

node --check "${telegram_bot_file}" >/dev/null

if [[ "${OPENCLAW_RUN_CODEX_SMOKE:-0}" == "1" ]]; then
  "${ROOT}/scripts/probe-codex-harness-turn.sh"
fi

if command -v systemctl >/dev/null 2>&1 && systemctl cat openclaw-gateway.service >/dev/null 2>&1; then
  actual_systemd_oom_policy="$(
    systemctl show openclaw-gateway.service --property=OOMPolicy --value 2>/dev/null || true
  )"

  if [[ "${actual_systemd_oom_policy}" != "${EXPECTED_SYSTEMD_OOM_POLICY}" ]]; then
    echo "OpenClaw gateway systemd OOMPolicy mismatch: expected ${EXPECTED_SYSTEMD_OOM_POLICY}, got ${actual_systemd_oom_policy:-<unset>}." >&2
    echo "A child process OOM must not stop/restart the whole gateway. Reinstall the unit with scripts/install-gateway-systemd.sh." >&2
    exit 1
  fi
fi

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

if ! primary_model_is_allowed "${actual_model}"; then
  echo "Model/runtime mismatch: expected primary ${EXPECTED_PRIMARY_MODEL} or a shared newer codex/<model> through the bundled Codex app-server harness, got ${actual_model}" >&2
  echo "Do not use codex-cli/* as the primary Telegram/OpenClaw runtime on this host class; it is a fallback backend only." >&2
  emit_newer_model_note
  exit 1
fi

actual_codex_plugin_enabled="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get plugins.entries.codex.enabled 2>/dev/null || true
)"

if [[ "${actual_codex_plugin_enabled}" != "true" ]]; then
  echo "Codex plugin mismatch: expected plugins.entries.codex.enabled=true, got ${actual_codex_plugin_enabled:-<unset>}" >&2
  exit 1
fi

actual_harness_runtime="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.embeddedHarness.runtime 2>/dev/null || true
)"

if [[ "${actual_harness_runtime}" != "${EXPECTED_HARNESS_RUNTIME}" ]]; then
  echo "Embedded harness runtime mismatch: expected ${EXPECTED_HARNESS_RUNTIME}, got ${actual_harness_runtime:-<unset>}" >&2
  exit 1
fi

actual_harness_fallback="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.embeddedHarness.fallback 2>/dev/null || true
)"

if [[ "${actual_harness_fallback}" != "${EXPECTED_HARNESS_FALLBACK}" ]]; then
  echo "Embedded harness fallback mismatch: expected ${EXPECTED_HARNESS_FALLBACK}, got ${actual_harness_fallback:-<unset>}" >&2
  exit 1
fi

actual_thinking_default="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.thinkingDefault 2>/dev/null || true
)"

if [[ "${actual_thinking_default}" != "${EXPECTED_THINKING_DEFAULT}" ]]; then
  echo "OpenClaw thinking default mismatch: expected ${EXPECTED_THINKING_DEFAULT}, got ${actual_thinking_default:-<unset>}" >&2
  exit 1
fi

actual_app_server_approval_policy="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get plugins.entries.codex.config.appServer.approvalPolicy 2>/dev/null || true
)"

if [[ "${actual_app_server_approval_policy}" != "${EXPECTED_CODEX_APP_SERVER_APPROVAL_POLICY}" ]]; then
  echo "Codex app-server approval policy mismatch: expected ${EXPECTED_CODEX_APP_SERVER_APPROVAL_POLICY}, got ${actual_app_server_approval_policy:-<unset>}" >&2
  exit 1
fi

actual_app_server_sandbox="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get plugins.entries.codex.config.appServer.sandbox 2>/dev/null || true
)"

if [[ "${actual_app_server_sandbox}" != "${EXPECTED_CODEX_APP_SERVER_SANDBOX}" ]]; then
  echo "Codex app-server sandbox mismatch: expected ${EXPECTED_CODEX_APP_SERVER_SANDBOX}, got ${actual_app_server_sandbox:-<unset>}" >&2
  exit 1
fi

actual_app_server_timeout_ms="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get plugins.entries.codex.config.appServer.requestTimeoutMs 2>/dev/null || true
)"

if [[ ! "${actual_app_server_timeout_ms}" =~ ^[0-9]+$ ]] || (( actual_app_server_timeout_ms < EXPECTED_CODEX_APP_SERVER_TIMEOUT_MS )); then
  echo "Codex app-server request timeout mismatch: expected at least ${EXPECTED_CODEX_APP_SERVER_TIMEOUT_MS}, got ${actual_app_server_timeout_ms:-<unset>}" >&2
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

  actual_context_pruning_mode="$(
    env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
      "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.contextPruning.mode 2>/dev/null || true
  )"

  if [[ "${actual_context_pruning_mode}" != "${EXPECTED_CONTEXT_PRUNING_MODE}" ]]; then
    echo "Context pruning mode mismatch: expected ${EXPECTED_CONTEXT_PRUNING_MODE}, got ${actual_context_pruning_mode:-<unset>}" >&2
    exit 1
  fi

  actual_context_pruning_ttl="$(
    env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
      "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.contextPruning.ttl 2>/dev/null || true
  )"

  if [[ "${actual_context_pruning_ttl}" != "${EXPECTED_CONTEXT_PRUNING_TTL}" ]]; then
    echo "Context pruning ttl mismatch: expected ${EXPECTED_CONTEXT_PRUNING_TTL}, got ${actual_context_pruning_ttl:-<unset>}" >&2
    exit 1
  fi

  actual_session_reset_mode="$(
    env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
      "${ROOT}/.openclaw/bin/openclaw" config get session.reset.mode 2>/dev/null || true
  )"

  if [[ "${actual_session_reset_mode}" != "${EXPECTED_SESSION_RESET_MODE}" ]]; then
    echo "Session reset mode mismatch: expected ${EXPECTED_SESSION_RESET_MODE}, got ${actual_session_reset_mode:-<unset>}" >&2
    exit 1
  fi

  actual_session_reset_hour="$(
    env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
      "${ROOT}/.openclaw/bin/openclaw" config get session.reset.atHour 2>/dev/null || true
  )"

  if [[ "${actual_session_reset_hour}" != "${EXPECTED_SESSION_RESET_HOUR}" ]]; then
    echo "Session reset hour mismatch: expected ${EXPECTED_SESSION_RESET_HOUR}, got ${actual_session_reset_hour:-<unset>}" >&2
    exit 1
  fi

  actual_direct_reset_mode="$(
    env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
      "${ROOT}/.openclaw/bin/openclaw" config get session.resetByType.direct.mode 2>/dev/null || true
  )"

  if [[ "${actual_direct_reset_mode}" != "${EXPECTED_DIRECT_RESET_MODE}" ]]; then
    echo "Direct session reset mode mismatch: expected ${EXPECTED_DIRECT_RESET_MODE}, got ${actual_direct_reset_mode:-<unset>}" >&2
    exit 1
  fi

  actual_direct_reset_idle_minutes="$(
    env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
      "${ROOT}/.openclaw/bin/openclaw" config get session.resetByType.direct.idleMinutes 2>/dev/null || true
  )"

  if [[ "${actual_direct_reset_idle_minutes}" != "${EXPECTED_DIRECT_RESET_IDLE_MINUTES}" ]]; then
    echo "Direct session reset idle mismatch: expected ${EXPECTED_DIRECT_RESET_IDLE_MINUTES}, got ${actual_direct_reset_idle_minutes:-<unset>}" >&2
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
  echo "Codex CLI resume args mismatch. Resume runs must bypass the Codex CLI sandbox and must not include fresh-only flags such as --color." >&2
  echo "Expected: ${EXPECTED_CODEX_CLI_RESUME_ARGS_JSON}" >&2
  echo "Got: ${actual_codex_cli_resume_args:-<unset>}" >&2
  exit 1
fi

actual_codex_cli_output="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.cliBackends.codex-cli.output 2>/dev/null || true
)"

if [[ "${actual_codex_cli_output}" != "${EXPECTED_CODEX_CLI_OUTPUT_MODE}" ]]; then
  echo "Codex CLI output mode mismatch. Fresh codex exec uses --json, so OpenClaw must parse it as jsonl." >&2
  echo "Expected: ${EXPECTED_CODEX_CLI_OUTPUT_MODE}" >&2
  echo "Got: ${actual_codex_cli_output:-<unset>}" >&2
  exit 1
fi

actual_codex_cli_resume_output="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.cliBackends.codex-cli.resumeOutput 2>/dev/null || true
)"

if [[ "${actual_codex_cli_resume_output}" != "${EXPECTED_CODEX_CLI_OUTPUT_MODE}" ]]; then
  echo "Codex CLI resume output mode mismatch. Resume codex exec uses --json, so resumeOutput must be jsonl or Telegram may receive raw JSONL/tool output." >&2
  echo "Expected: ${EXPECTED_CODEX_CLI_OUTPUT_MODE}" >&2
  echo "Got: ${actual_codex_cli_resume_output:-<unset>}" >&2
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
