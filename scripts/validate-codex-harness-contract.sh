#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENCLAW_HOME_DIR="${OPENCLAW_HOME:-${ROOT}/.openclaw-home}"
OPENCLAW_BIN="${ROOT}/.openclaw/bin/openclaw"
BASELINE_MODEL="gpt-5.4"
EXPECTED_PROVIDER="codex"
EXPECTED_MODEL_PREFIX="codex/"
EXPECTED_THINKING_DEFAULT="xhigh"
EXPECTED_HARNESS_RUNTIME="codex"
EXPECTED_HARNESS_FALLBACK="pi"
EXPECTED_CODEX_APP_SERVER_APPROVAL_POLICY="never"
EXPECTED_CODEX_APP_SERVER_SANDBOX="danger-full-access"
EXPECTED_CODEX_APP_SERVER_TIMEOUT_MS=604800000

require_fixed_string() {
  local pattern="$1"
  local file="$2"
  if ! grep -F --quiet -- "${pattern}" "${file}"; then
    echo "Missing required Codex harness contract string in ${file}: ${pattern}" >&2
    exit 1
  fi
}

require_fixed_string "codex/${BASELINE_MODEL}" "${ROOT}/scripts/bootstrap-openclaw.sh"
require_fixed_string "plugins.entries.codex.enabled" "${ROOT}/scripts/bootstrap-openclaw.sh"
require_fixed_string "agents.defaults.embeddedHarness.runtime" "${ROOT}/scripts/bootstrap-openclaw.sh"
require_fixed_string "agents.defaults.embeddedHarness.fallback" "${ROOT}/scripts/bootstrap-openclaw.sh"
require_fixed_string "agents.defaults.thinkingDefault" "${ROOT}/scripts/bootstrap-openclaw.sh"
require_fixed_string "plugins.entries.codex.config.appServer.sandbox" "${ROOT}/scripts/bootstrap-openclaw.sh"
require_fixed_string "plugins.entries.codex.config.appServer.requestTimeoutMs" "${ROOT}/scripts/bootstrap-openclaw.sh"
require_fixed_string "codex/${BASELINE_MODEL}" "${ROOT}/scripts/validate-local-setup.sh"
require_fixed_string "agents.defaults.embeddedHarness.runtime" "${ROOT}/scripts/validate-local-setup.sh"
require_fixed_string "agents.defaults.thinkingDefault" "${ROOT}/scripts/validate-local-setup.sh"

bad_primary_matches="$(
  git -C "${ROOT}" grep -n -E 'primary baseline model: codex-cli/|baseline model: `codex-cli/|primary model to `codex-cli/|MUST use `codex-cli/' -- \
    AGENTS.md README.md docs workspace scripts ':!scripts/validate-codex-harness-contract.sh' 2>/dev/null || true
)"

if [[ -n "${bad_primary_matches}" ]]; then
  echo "Found docs/scripts that still describe codex-cli/* as the primary model path. codex-cli is fallback-only on this host class:" >&2
  printf '%s\n' "${bad_primary_matches}" >&2
  exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
  echo "Codex CLI not found on PATH; the Codex app-server harness cannot run." >&2
  exit 1
fi

app_server_help="$(codex app-server --help)"
if [[ "${app_server_help}" != *"--listen"* || "${app_server_help}" != *"stdio://"* ]]; then
  echo "Current Codex CLI app-server help does not advertise the expected stdio listener." >&2
  exit 1
fi

if [[ -x "${OPENCLAW_BIN}" && -f "${OPENCLAW_HOME_DIR}/.openclaw/openclaw.json" ]]; then
  actual_model="$(
    env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" \
      "${OPENCLAW_BIN}" config get agents.defaults.model.primary 2>/dev/null || true
  )"

  if [[ "${actual_model}" != "${EXPECTED_MODEL_PREFIX}"* ]]; then
    echo "Live OpenClaw primary model must use the Codex app-server provider (${EXPECTED_MODEL_PREFIX}...), got ${actual_model:-<unset>}" >&2
    echo "Do not use codex-cli/* as the primary Telegram/OpenClaw runtime; it is a fallback backend only." >&2
    exit 1
  fi

  actual_codex_plugin_enabled="$(
    env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" \
      "${OPENCLAW_BIN}" config get plugins.entries.codex.enabled 2>/dev/null || true
  )"

  if [[ "${actual_codex_plugin_enabled}" != "true" ]]; then
    echo "Live OpenClaw Codex plugin must be explicitly enabled, got ${actual_codex_plugin_enabled:-<unset>}" >&2
    exit 1
  fi

  actual_harness_runtime="$(
    env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" \
      "${OPENCLAW_BIN}" config get agents.defaults.embeddedHarness.runtime 2>/dev/null || true
  )"

  if [[ "${actual_harness_runtime}" != "${EXPECTED_HARNESS_RUNTIME}" ]]; then
    echo "Live OpenClaw embedded harness runtime mismatch: expected ${EXPECTED_HARNESS_RUNTIME}, got ${actual_harness_runtime:-<unset>}" >&2
    exit 1
  fi

  actual_harness_fallback="$(
    env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" \
      "${OPENCLAW_BIN}" config get agents.defaults.embeddedHarness.fallback 2>/dev/null || true
  )"

  if [[ "${actual_harness_fallback}" != "${EXPECTED_HARNESS_FALLBACK}" ]]; then
    echo "Live OpenClaw embedded harness fallback mismatch: expected ${EXPECTED_HARNESS_FALLBACK}, got ${actual_harness_fallback:-<unset>}" >&2
    exit 1
  fi

  actual_thinking_default="$(
    env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" \
      "${OPENCLAW_BIN}" config get agents.defaults.thinkingDefault 2>/dev/null || true
  )"

  if [[ "${actual_thinking_default}" != "${EXPECTED_THINKING_DEFAULT}" ]]; then
    echo "Live OpenClaw thinking default mismatch: expected ${EXPECTED_THINKING_DEFAULT}, got ${actual_thinking_default:-<unset>}" >&2
    exit 1
  fi

  actual_app_server_approval_policy="$(
    env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" \
      "${OPENCLAW_BIN}" config get plugins.entries.codex.config.appServer.approvalPolicy 2>/dev/null || true
  )"

  if [[ "${actual_app_server_approval_policy}" != "${EXPECTED_CODEX_APP_SERVER_APPROVAL_POLICY}" ]]; then
    echo "Live Codex app-server approval policy mismatch: expected ${EXPECTED_CODEX_APP_SERVER_APPROVAL_POLICY}, got ${actual_app_server_approval_policy:-<unset>}" >&2
    exit 1
  fi

  actual_app_server_sandbox="$(
    env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" \
      "${OPENCLAW_BIN}" config get plugins.entries.codex.config.appServer.sandbox 2>/dev/null || true
  )"

  if [[ "${actual_app_server_sandbox}" != "${EXPECTED_CODEX_APP_SERVER_SANDBOX}" ]]; then
    echo "Live Codex app-server sandbox mismatch: expected ${EXPECTED_CODEX_APP_SERVER_SANDBOX}, got ${actual_app_server_sandbox:-<unset>}" >&2
    exit 1
  fi

  actual_app_server_timeout_ms="$(
    env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" \
      "${OPENCLAW_BIN}" config get plugins.entries.codex.config.appServer.requestTimeoutMs 2>/dev/null || true
  )"

  if [[ ! "${actual_app_server_timeout_ms}" =~ ^[0-9]+$ ]] || (( actual_app_server_timeout_ms < EXPECTED_CODEX_APP_SERVER_TIMEOUT_MS )); then
    echo "Live Codex app-server request timeout mismatch: expected at least ${EXPECTED_CODEX_APP_SERVER_TIMEOUT_MS}, got ${actual_app_server_timeout_ms:-<unset>}" >&2
    exit 1
  fi

  plugin_probe="$(
    env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" \
      "${OPENCLAW_BIN}" plugins inspect codex --json 2>/dev/null || true
  )"

  if [[ -z "${plugin_probe}" ]]; then
    echo "Unable to inspect the bundled Codex plugin." >&2
    exit 1
  fi

  if ! jq -e --arg provider "${EXPECTED_PROVIDER}" '.plugin.providerIds | index($provider)' >/dev/null <<<"${plugin_probe}"; then
    echo "Bundled Codex plugin is not exposing provider id ${EXPECTED_PROVIDER}." >&2
    exit 1
  fi

  if ! jq -e --arg runtime "${EXPECTED_HARNESS_RUNTIME}" '.plugin.agentHarnessIds | index($runtime)' >/dev/null <<<"${plugin_probe}"; then
    echo "Bundled Codex plugin is not exposing agent harness id ${EXPECTED_HARNESS_RUNTIME}." >&2
    exit 1
  fi
fi

echo "Codex app-server harness contract validated."
