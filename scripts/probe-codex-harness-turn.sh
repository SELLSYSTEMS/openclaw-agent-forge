#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENCLAW_HOME_DIR="${OPENCLAW_HOME:-${ROOT}/.openclaw-home}"
OPENCLAW_BIN="${ROOT}/.openclaw/bin/openclaw"
SMOKE_TEXT="${OPENCLAW_CODEX_SMOKE_TEXT:-OPENCLAW-CODEX-HARNESS-SMOKE}"
SMOKE_TIMEOUT_SECONDS="${OPENCLAW_CODEX_SMOKE_TIMEOUT_SECONDS:-90}"

if [[ ! -x "${OPENCLAW_BIN}" ]]; then
  echo "OpenClaw binary is missing: ${OPENCLAW_BIN}" >&2
  exit 1
fi

MODEL_REF="${OPENCLAW_SMOKE_MODEL:-}"
if [[ -z "${MODEL_REF}" ]]; then
  MODEL_REF="$(
    env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" \
      "${OPENCLAW_BIN}" config get agents.defaults.model.primary 2>/dev/null || true
  )"
fi

if [[ "${MODEL_REF}" != codex/* ]]; then
  echo "Codex harness smoke requires a codex/<model> primary model, got ${MODEL_REF:-<unset>}" >&2
  exit 1
fi

MODEL_NAME="${MODEL_REF#codex/}"
TMP_OUTPUT="$(mktemp)"
trap 'rm -f "${TMP_OUTPUT}"' EXIT

set +e
{
  timeout --kill-after=5s "${SMOKE_TIMEOUT_SECONDS}" \
    env OPENCLAW_HOME="${OPENCLAW_HOME_DIR}" \
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
  echo "Codex harness smoke passed: provider=codex model=${MODEL_NAME} produced the expected response."
  if [[ "${status}" == "124" ]]; then
    echo "Note: OpenClaw emitted the expected Codex result before the smoke timeout; timeout cleaned up the one-shot local app-server process." >&2
  elif [[ "${status}" != "0" ]]; then
    echo "Note: OpenClaw emitted the expected Codex result with non-zero wrapper status ${status}." >&2
  fi
  exit 0
fi

echo "Codex harness smoke failed for ${MODEL_REF}; output follows." >&2
cat "${TMP_OUTPUT}" >&2
exit 1
