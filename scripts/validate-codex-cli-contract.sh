#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENCLAW_HOME_DIR="${OPENCLAW_HOME:-${ROOT}/.openclaw-home}"
OPENCLAW_BIN="${ROOT}/.openclaw/bin/openclaw"
EXPECTED_CODEX_CLI_ARGS_JSON='["exec","--json","--color","never","--dangerously-bypass-approvals-and-sandbox","--skip-git-repo-check"]'
EXPECTED_CODEX_CLI_RESUME_ARGS_JSON='["exec","resume","--json","--dangerously-bypass-approvals-and-sandbox","--skip-git-repo-check","{sessionId}"]'
EXPECTED_CODEX_CLI_OUTPUT_MODE="jsonl"
LEGACY_BAD_RESUME_ARGS_JSON='["exec","resume","{sessionId}","--color","never","--dangerously-bypass-approvals-and-sandbox","--skip-git-repo-check"]'

compact_json() {
  tr -d '[:space:]'
}

require_fixed_string() {
  local pattern="$1"
  local file="$2"
  if ! grep -F --quiet -- "${pattern}" "${file}"; then
    echo "Missing required Codex CLI contract string in ${file}: ${pattern}" >&2
    exit 1
  fi
}

EXPECTED_CODEX_CLI_ARGS_COMPACT="$(printf '%s' "${EXPECTED_CODEX_CLI_ARGS_JSON}" | compact_json)"
EXPECTED_CODEX_CLI_RESUME_ARGS_COMPACT="$(printf '%s' "${EXPECTED_CODEX_CLI_RESUME_ARGS_JSON}" | compact_json)"

require_fixed_string "${EXPECTED_CODEX_CLI_ARGS_JSON}" "${ROOT}/scripts/bootstrap-openclaw.sh"
require_fixed_string "${EXPECTED_CODEX_CLI_RESUME_ARGS_JSON}" "${ROOT}/scripts/bootstrap-openclaw.sh"
require_fixed_string "agents.defaults.cliBackends.codex-cli.output" "${ROOT}/scripts/bootstrap-openclaw.sh"
require_fixed_string "agents.defaults.cliBackends.codex-cli.resumeOutput" "${ROOT}/scripts/bootstrap-openclaw.sh"
require_fixed_string "${EXPECTED_CODEX_CLI_ARGS_JSON}" "${ROOT}/scripts/validate-local-setup.sh"
require_fixed_string "${EXPECTED_CODEX_CLI_RESUME_ARGS_JSON}" "${ROOT}/scripts/validate-local-setup.sh"
require_fixed_string "agents.defaults.cliBackends.codex-cli.output" "${ROOT}/scripts/validate-local-setup.sh"
require_fixed_string "agents.defaults.cliBackends.codex-cli.resumeOutput" "${ROOT}/scripts/validate-local-setup.sh"

bad_matches="$(
  git -C "${ROOT}" grep -n -F -- "${LEGACY_BAD_RESUME_ARGS_JSON}" -- . ':!scripts/validate-codex-cli-contract.sh' 2>/dev/null || true
)"

if [[ -n "${bad_matches}" ]]; then
  echo "Legacy bad Codex CLI resume args found. Do not put fresh-only --color flags into resumeArgs:" >&2
  printf '%s\n' "${bad_matches}" >&2
  exit 1
fi

if [[ -x "${OPENCLAW_BIN}" && -f "${OPENCLAW_HOME_DIR}/.openclaw/openclaw.json" ]]; then
  actual_codex_cli_args="$(
    env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" \
      "${OPENCLAW_BIN}" config get agents.defaults.cliBackends.codex-cli.args 2>/dev/null || true
  )"

  if [[ "$(printf '%s' "${actual_codex_cli_args}" | compact_json)" != "${EXPECTED_CODEX_CLI_ARGS_COMPACT}" ]]; then
    echo "Live OpenClaw Codex CLI fresh args mismatch." >&2
    echo "Expected: ${EXPECTED_CODEX_CLI_ARGS_JSON}" >&2
    echo "Got: ${actual_codex_cli_args:-<unset>}" >&2
    exit 1
  fi

  actual_codex_cli_resume_args="$(
    env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" \
      "${OPENCLAW_BIN}" config get agents.defaults.cliBackends.codex-cli.resumeArgs 2>/dev/null || true
  )"

  if [[ "$(printf '%s' "${actual_codex_cli_resume_args}" | compact_json)" != "${EXPECTED_CODEX_CLI_RESUME_ARGS_COMPACT}" ]]; then
    echo "Live OpenClaw Codex CLI resume args mismatch." >&2
    echo "Expected: ${EXPECTED_CODEX_CLI_RESUME_ARGS_JSON}" >&2
    echo "Got: ${actual_codex_cli_resume_args:-<unset>}" >&2
    exit 1
  fi

  actual_codex_cli_output="$(
    env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" \
      "${OPENCLAW_BIN}" config get agents.defaults.cliBackends.codex-cli.output 2>/dev/null || true
  )"

  if [[ "${actual_codex_cli_output}" != "${EXPECTED_CODEX_CLI_OUTPUT_MODE}" ]]; then
    echo "Live OpenClaw Codex CLI output mode mismatch." >&2
    echo "Expected: ${EXPECTED_CODEX_CLI_OUTPUT_MODE}" >&2
    echo "Got: ${actual_codex_cli_output:-<unset>}" >&2
    exit 1
  fi

  actual_codex_cli_resume_output="$(
    env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" \
      "${OPENCLAW_BIN}" config get agents.defaults.cliBackends.codex-cli.resumeOutput 2>/dev/null || true
  )"

  if [[ "${actual_codex_cli_resume_output}" != "${EXPECTED_CODEX_CLI_OUTPUT_MODE}" ]]; then
    echo "Live OpenClaw Codex CLI resume output mode mismatch. Resume uses --json, so resumeOutput must stay jsonl or Telegram may receive raw JSONL." >&2
    echo "Expected: ${EXPECTED_CODEX_CLI_OUTPUT_MODE}" >&2
    echo "Got: ${actual_codex_cli_resume_output:-<unset>}" >&2
    exit 1
  fi
fi

if command -v codex >/dev/null 2>&1; then
  fresh_help="$(codex exec --help)"
  resume_help="$(codex exec resume --help)"

  for required_flag in "--json" "--color" "--dangerously-bypass-approvals-and-sandbox" "--skip-git-repo-check"; do
    if [[ "${fresh_help}" != *"${required_flag}"* ]]; then
      echo "Current Codex CLI fresh exec help no longer advertises required flag: ${required_flag}" >&2
      exit 1
    fi
  done

  for required_flag in "--json" "--dangerously-bypass-approvals-and-sandbox" "--skip-git-repo-check"; do
    if [[ "${resume_help}" != *"${required_flag}"* ]]; then
      echo "Current Codex CLI resume help no longer advertises required flag: ${required_flag}" >&2
      exit 1
    fi
  done

  if [[ "${resume_help}" == *"--color"* ]]; then
    echo "Warning: Codex CLI resume now advertises --color, but this repo intentionally keeps resumeArgs minimal and validated separately." >&2
  fi
else
  echo "Codex CLI not found on PATH; skipped live Codex help compatibility check."
fi

echo "Codex CLI backend contract validated."
