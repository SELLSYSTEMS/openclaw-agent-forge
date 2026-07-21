#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_OPENCLAW_HOME_DIR="${OPENCLAW_HOME:-${ROOT}/.openclaw-home}"
OPENCLAW_BIN="${ROOT}/.openclaw/bin/openclaw"
SMOKE_TEXT="${OPENCLAW_CODEX_SMOKE_TEXT:-OPENCLAW-CODEX-HARNESS-SMOKE}"
SMOKE_TIMEOUT_SECONDS="${OPENCLAW_CODEX_SMOKE_TIMEOUT_SECONDS:-300}"
EXPECTED_THINKING_DEFAULT="${OPENCLAW_SMOKE_THINKING:-max}"
SOURCE_CONFIG_FILE="${SOURCE_OPENCLAW_HOME_DIR}/.openclaw/openclaw.json"

if [[ ! -x "${OPENCLAW_BIN}" ]]; then
  echo "OpenClaw binary is missing: ${OPENCLAW_BIN}" >&2
  exit 1
fi

if [[ ! -f "${SOURCE_CONFIG_FILE}" ]]; then
  echo "OpenClaw config is missing: ${SOURCE_CONFIG_FILE}" >&2
  exit 1
fi

MODEL_REF="${OPENCLAW_SMOKE_MODEL:-}"
if [[ -z "${MODEL_REF}" ]]; then
  MODEL_REF="$(
    env OPENCLAW_HOME="${SOURCE_OPENCLAW_HOME_DIR}" \
      "${OPENCLAW_BIN}" config get agents.defaults.model.primary 2>/dev/null || true
  )"
fi

if [[ "${MODEL_REF}" != codex/* ]]; then
  echo "Codex harness smoke requires a codex/<model> primary model, got ${MODEL_REF:-<unset>}" >&2
  exit 1
fi

ACTUAL_THINKING_DEFAULT="$(
  env OPENCLAW_HOME="${SOURCE_OPENCLAW_HOME_DIR}" \
    "${OPENCLAW_BIN}" config get agents.defaults.thinkingDefault 2>/dev/null || true
)"

if [[ "${ACTUAL_THINKING_DEFAULT}" != "${EXPECTED_THINKING_DEFAULT}" ]]; then
  echo "Codex harness smoke requires thinkingDefault=${EXPECTED_THINKING_DEFAULT}, got ${ACTUAL_THINKING_DEFAULT:-<unset>}" >&2
  exit 1
fi

MODEL_NAME="${MODEL_REF#codex/}"
TMP_OUTPUT="$(mktemp)"
SMOKE_OPENCLAW_HOME="$(mktemp -d)"
trap 'rm -f "${TMP_OUTPUT}"; rm -rf "${SMOKE_OPENCLAW_HOME}"' EXIT
mkdir -p "${SMOKE_OPENCLAW_HOME}/.openclaw"
cp --preserve=mode,timestamps "${SOURCE_CONFIG_FILE}" "${SMOKE_OPENCLAW_HOME}/.openclaw/openclaw.json"

set +e
{
  timeout --kill-after=5s "${SMOKE_TIMEOUT_SECONDS}" \
    env OPENCLAW_HOME="${SMOKE_OPENCLAW_HOME}" \
    "${OPENCLAW_BIN}" infer model run \
      --model "${MODEL_REF}" \
      --prompt "Reply exactly: ${SMOKE_TEXT}" \
      --json >"${TMP_OUTPUT}" 2>&1
  status=$?
} 2>/dev/null
set -e

if grep -F --quiet '"provider": "codex"' "${TMP_OUTPUT}" \
  && grep -F --quiet "\"model\": \"${MODEL_NAME}\"" "${TMP_OUTPUT}" \
  && grep -F --quiet "\"text\": \"${SMOKE_TEXT}\"" "${TMP_OUTPUT}"; then
  echo "Codex harness smoke passed in isolated state: provider=codex model=${MODEL_NAME} thinking=${ACTUAL_THINKING_DEFAULT} produced the expected response."
  if [[ "${status}" == "124" || "${status}" == "137" ]]; then
    echo "Note: OpenClaw emitted the expected Codex result before the smoke timeout; timeout cleaned up the one-shot local app-server process." >&2
  elif [[ "${status}" != "0" ]]; then
    echo "Note: OpenClaw emitted the expected Codex result with non-zero wrapper status ${status}." >&2
  fi
  exit 0
fi

echo "Codex harness smoke failed for ${MODEL_REF}; output follows." >&2
cat "${TMP_OUTPUT}" >&2
exit 1
