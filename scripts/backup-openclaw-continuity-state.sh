#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENCLAW_HOME_DIR="${OPENCLAW_HOME:-${ROOT}/.openclaw-home}"
STATE_DIR="${OPENCLAW_HOME_DIR}/.openclaw"
CONFIG_FILE="${STATE_DIR}/openclaw.json"
SESSION_STORE="${STATE_DIR}/agents/main/sessions/sessions.json"
SESSION_KEY="${OPENCLAW_SESSION_KEY:-agent:main:main}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="${OPENCLAW_BACKUP_DIR:-${OPENCLAW_HOME_DIR}/backups/session-continuity-${STAMP}}"

umask 077

for required_file in "${CONFIG_FILE}" "${SESSION_STORE}"; do
  if [[ ! -f "${required_file}" ]]; then
    echo "Required OpenClaw state file is missing: ${required_file}" >&2
    exit 1
  fi
done

SESSION_ID="$(jq -er --arg key "${SESSION_KEY}" '.[$key].sessionId | select(type == "string" and length > 0)' "${SESSION_STORE}")"
SESSION_FILE="$(jq -er --arg key "${SESSION_KEY}" '.[$key].sessionFile | select(type == "string" and length > 0)' "${SESSION_STORE}")"
SESSION_FILE="$(realpath -e -- "${SESSION_FILE}")"
EXPECTED_SESSION_ROOT="$(realpath -e -- "${STATE_DIR}/agents")/"

if [[ "${SESSION_FILE}" != "${EXPECTED_SESSION_ROOT}"* || ! -f "${SESSION_FILE}" ]]; then
  echo "Refusing to back up an invalid or out-of-tree session file: ${SESSION_FILE}" >&2
  exit 1
fi

SIDECAR_FILE="${SESSION_FILE}.codex-app-server.json"
if [[ -e "${BACKUP_DIR}" ]]; then
  echo "Refusing to overwrite an existing continuity backup: ${BACKUP_DIR}" >&2
  exit 1
fi

install -d -m 700 "${BACKUP_DIR}"
cp --preserve=mode,timestamps "${CONFIG_FILE}" "${BACKUP_DIR}/openclaw.json"
cp --preserve=mode,timestamps "${SESSION_STORE}" "${BACKUP_DIR}/sessions.json"
cp --preserve=mode,timestamps "${SESSION_FILE}" "${BACKUP_DIR}/$(basename "${SESSION_FILE}")"

if [[ -f "${SIDECAR_FILE}" ]]; then
  cp --preserve=mode,timestamps "${SIDECAR_FILE}" "${BACKUP_DIR}/$(basename "${SIDECAR_FILE}")"
fi

(
  cd "${BACKUP_DIR}"
  sha256sum -- * > SHA256SUMS
)

printf 'OpenClaw continuity backup created.\n'
printf 'backup=%s\n' "${BACKUP_DIR}"
printf 'session_key=%s\n' "${SESSION_KEY}"
printf 'session_id=%s\n' "${SESSION_ID}"
printf 'transcript_bytes=%s\n' "$(stat -c %s "${SESSION_FILE}")"
printf 'codex_sidecar=%s\n' "$(if [[ -f "${SIDECAR_FILE}" ]]; then printf present; else printf absent; fi)"
