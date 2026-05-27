#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFIX="${ROOT}/.openclaw"
OPENCLAW_HOME_DIR="${ROOT}/.openclaw-home"
WORKSPACE_DIR="${ROOT}/workspace"
MEMORY_DIR="${ROOT}/memory"
SHARED_CODEX_CONFIG="${CODEX_CONFIG:-${HOME}/.codex/config.toml}"
BASELINE_MODEL="gpt-5.4"
BASELINE_MODEL_REF="codex/gpt-5.4"
BASELINE_REASONING="xhigh"
OPENCLAW_THINKING_DEFAULT="xhigh"
LONG_RUN_TIMEOUT_SECONDS=604800
LONG_RUN_WATCHDOG_TIMEOUT_MS=604800000
CODEX_APP_SERVER_TIMEOUT_MS=604800000
EXPECTED_CONTEXT_INJECTION="continuation-skip"
EXPECTED_SANDBOX_MODE="off"
EXPECTED_CONTEXT_PRUNING_MODE="cache-ttl"
EXPECTED_CONTEXT_PRUNING_TTL="5m"
EXPECTED_SESSION_RESET_MODE="daily"
EXPECTED_SESSION_RESET_HOUR=4
EXPECTED_DIRECT_RESET_MODE="idle"
EXPECTED_DIRECT_RESET_IDLE_MINUTES=240
CODEX_HARNESS_RUNTIME="codex"
CODEX_HARNESS_FALLBACK="pi"
CODEX_APP_SERVER_APPROVAL_POLICY="never"
CODEX_APP_SERVER_SANDBOX="danger-full-access"
CODEX_CLI_ARGS_JSON='["exec","--json","--color","never","--dangerously-bypass-approvals-and-sandbox","--skip-git-repo-check"]'
CODEX_CLI_RESUME_ARGS_JSON='["exec","resume","--json","--dangerously-bypass-approvals-and-sandbox","--skip-git-repo-check","{sessionId}"]'
CODEX_CLI_OUTPUT_MODE="jsonl"
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

resolve_requested_model_ref() {
  local requested_model="${OPENCLAW_PRIMARY_MODEL:-${OPENCLAW_MODEL:-}}"
  if [[ -n "${requested_model}" ]]; then
    if [[ "${requested_model}" == codex/* ]]; then
      printf '%s\n' "${requested_model}"
      return
    fi

    if [[ "${requested_model}" == gpt-* ]]; then
      printf 'codex/%s\n' "${requested_model}"
      return
    fi

    echo "Unsupported OPENCLAW_PRIMARY_MODEL value: ${requested_model}" >&2
    echo "Use codex/gpt-5.4, codex/<validated-newer-model>, or a bare gpt-* model name." >&2
    exit 1
  fi

  printf '%s\n' "${BASELINE_MODEL_REF}"
}

resolve_shared_model() {
  local shared_model=""
  if [[ -f "${SHARED_CODEX_CONFIG}" ]]; then
    shared_model="$(extract_toml_string model "${SHARED_CODEX_CONFIG}" || true)"
  fi

  if [[ -n "${shared_model}" ]]; then
    printf '%s\n' "${shared_model}"
  fi
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

"${ROOT}/scripts/apply-openclaw-runtime-patches.sh"

TARGET_PRIMARY_MODEL="$(resolve_requested_model_ref)"

env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.workspace "${WORKSPACE_DIR}"
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" models set "${TARGET_PRIMARY_MODEL}"
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set plugins.entries.codex.enabled true
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set plugins.entries.codex.config.appServer.approvalPolicy "\"${CODEX_APP_SERVER_APPROVAL_POLICY}\"" --strict-json
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set plugins.entries.codex.config.appServer.sandbox "\"${CODEX_APP_SERVER_SANDBOX}\"" --strict-json
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set plugins.entries.codex.config.appServer.requestTimeoutMs "${CODEX_APP_SERVER_TIMEOUT_MS}"
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.embeddedHarness.runtime "\"${CODEX_HARNESS_RUNTIME}\"" --strict-json
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.embeddedHarness.fallback "\"${CODEX_HARNESS_FALLBACK}\"" --strict-json
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.thinkingDefault "\"${OPENCLAW_THINKING_DEFAULT}\"" --strict-json
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.timeoutSeconds "${LONG_RUN_TIMEOUT_SECONDS}"
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.llm.idleTimeoutSeconds 0
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.contextInjection "${EXPECTED_CONTEXT_INJECTION}"
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.contextPruning.mode "\"${EXPECTED_CONTEXT_PRUNING_MODE}\"" --strict-json
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.contextPruning.ttl "\"${EXPECTED_CONTEXT_PRUNING_TTL}\"" --strict-json
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.sandbox.mode "\"${EXPECTED_SANDBOX_MODE}\"" --strict-json
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set session.reset.mode "\"${EXPECTED_SESSION_RESET_MODE}\"" --strict-json
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set session.reset.atHour "${EXPECTED_SESSION_RESET_HOUR}"
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set session.resetByType.direct.mode "\"${EXPECTED_DIRECT_RESET_MODE}\"" --strict-json
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set session.resetByType.direct.idleMinutes "${EXPECTED_DIRECT_RESET_IDLE_MINUTES}"
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.cliBackends.codex-cli.command codex
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.cliBackends.codex-cli.args "${CODEX_CLI_ARGS_JSON}" --strict-json
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.cliBackends.codex-cli.resumeArgs "${CODEX_CLI_RESUME_ARGS_JSON}" --strict-json
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.cliBackends.codex-cli.output "\"${CODEX_CLI_OUTPUT_MODE}\"" --strict-json
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.cliBackends.codex-cli.resumeOutput "\"${CODEX_CLI_OUTPUT_MODE}\"" --strict-json
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.cliBackends.codex-cli.reliability.watchdog.fresh.noOutputTimeoutMs "${LONG_RUN_WATCHDOG_TIMEOUT_MS}"
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set agents.defaults.cliBackends.codex-cli.reliability.watchdog.resume.noOutputTimeoutMs "${LONG_RUN_WATCHDOG_TIMEOUT_MS}"
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set gateway.mode local
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config set gateway.bind loopback
env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" "${PREFIX}/bin/openclaw" config validate

"${ROOT}/scripts/setup-local-stt.sh"
"${ROOT}/scripts/validate-local-stt.sh"

if command -v codex >/dev/null 2>&1; then
  if ! codex login status >/dev/null 2>&1; then
    echo "Codex CLI is installed but not authenticated yet."
    echo "Run: codex login"
  fi
else
  echo "Codex CLI is not installed or not on PATH."
  echo "Install/login Codex CLI before using Codex-backed OpenClaw turns."
fi

echo "Requested OpenClaw primary model: ${TARGET_PRIMARY_MODEL}"
SHARED_MODEL="$(resolve_shared_model || true)"
if [[ -n "${SHARED_MODEL}" ]] && model_is_newer_than_baseline "${SHARED_MODEL}" && [[ "${TARGET_PRIMARY_MODEL}" != "codex/${SHARED_MODEL}" ]]; then
  echo "Note: shared Codex default is ${SHARED_MODEL}, but bootstrap keeps ${BASELINE_MODEL_REF} unless OPENCLAW_PRIMARY_MODEL is explicitly set after OpenClaw validation." >&2
fi
if [[ "$(resolve_shared_reasoning)" != "${BASELINE_REASONING}" ]]; then
  echo "Warning: shared Codex reasoning is not ${BASELINE_REASONING}. OpenClaw is expected to run with ${BASELINE_REASONING} reasoning on this host." >&2
fi

echo "Embedded Codex primary runtime: model=${TARGET_PRIMARY_MODEL}, thinkingDefault=${OPENCLAW_THINKING_DEFAULT}, harness=${CODEX_HARNESS_RUNTIME}, fallback=${CODEX_HARNESS_FALLBACK}, app-server sandbox=${CODEX_APP_SERVER_SANDBOX}, app-server requestTimeoutMs=${CODEX_APP_SERVER_TIMEOUT_MS}."
echo "Boot-safe fallback note: persisted embeddedHarness.fallback=${CODEX_HARNESS_FALLBACK} avoids gateway startup failure before the Codex plugin registers. Use fallback=none only in explicit smoke tests."
echo "Embedded Codex no-interruption policy: timeoutSeconds=${LONG_RUN_TIMEOUT_SECONDS}, llm.idleTimeoutSeconds=0, contextInjection=${EXPECTED_CONTEXT_INJECTION}, contextPruning=${EXPECTED_CONTEXT_PRUNING_MODE}/${EXPECTED_CONTEXT_PRUNING_TTL}, sandbox.mode=${EXPECTED_SANDBOX_MODE}, codex-cli fallback watchdog=${LONG_RUN_WATCHDOG_TIMEOUT_MS}ms."
echo "Embedded Codex CLI args: ${CODEX_CLI_ARGS_JSON}"
echo "Embedded Codex CLI resume args: ${CODEX_CLI_RESUME_ARGS_JSON}"
echo "Embedded Codex CLI output mode: output=${CODEX_CLI_OUTPUT_MODE}, resumeOutput=${CODEX_CLI_OUTPUT_MODE}"
echo "If Telegram is enabled later on this host, set channels.telegram.execApprovals.enabled=false unless you intentionally configure Telegram as a native exec-approval client."

echo "Bootstrap complete."
echo "Run: ${ROOT}/bin/openclaw-local"
