#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAMPLE_URL="${STT_SAMPLE_URL:-https://raw.githubusercontent.com/openai/whisper/main/tests/jfk.flac}"
SAMPLE_PATH="${STT_SAMPLE_PATH:-${ROOT}/.openclaw-home/cache/stt-sample-jfk.flac}"

mkdir -p "$(dirname "${SAMPLE_PATH}")"

"${ROOT}/scripts/setup-local-stt.sh" >/dev/null

if [[ ! -s "${SAMPLE_PATH}" ]]; then
  curl -fsSL "${SAMPLE_URL}" -o "${SAMPLE_PATH}"
fi

TRANSCRIPT="$("${ROOT}/scripts/transcribe-local.sh" "${SAMPLE_PATH}")"

if [[ -z "${TRANSCRIPT}" ]]; then
  echo "Local STT validation failed: empty transcript." >&2
  exit 1
fi

if ! printf '%s\n' "${TRANSCRIPT}" | grep -Eiq 'country|world|citizens'; then
  echo "Local STT validation failed: transcript did not match the expected JFK sample." >&2
  printf '%s\n' "${TRANSCRIPT}" >&2
  exit 1
fi

echo "Local STT sample validation passed."
