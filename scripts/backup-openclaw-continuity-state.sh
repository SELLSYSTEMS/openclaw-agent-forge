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
CODEX_HOME_DIR="${CODEX_HOME:-${HOME}/.codex}"
CODEX_ROLLOUT=""
if [[ -f "${SIDECAR_FILE}" ]]; then
  THREAD_ID="$(jq -er '.threadId | select(type == "string")' "${SIDECAR_FILE}")"
  if [[ ! "${THREAD_ID}" =~ ^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$ ]]; then
    echo "Invalid Codex thread id; refusing an incomplete continuity backup." >&2
    exit 1
  fi
  SEARCH_ROOTS=()
  for directory in "${CODEX_HOME_DIR}/sessions" "${CODEX_HOME_DIR}/archived_sessions"; do
    [[ ! -d "${directory}" ]] || SEARCH_ROOTS+=("${directory}")
  done
  ROLLOUTS=()
  if (( ${#SEARCH_ROOTS[@]} > 0 )); then
    mapfile -d '' -t ROLLOUTS < <(find "${SEARCH_ROOTS[@]}" -type f -name "*-${THREAD_ID}.jsonl" -print0)
  fi
  if (( ${#ROLLOUTS[@]} != 1 )); then
    echo "Expected one native Codex rollout for the bound thread; found ${#ROLLOUTS[@]}." >&2
    echo "Verify CODEX_HOME matches the gateway process before migrating." >&2
    exit 1
  fi
  CODEX_ROLLOUT="${ROLLOUTS[0]}"
  if ! head -n 1 "${CODEX_ROLLOUT}" | jq -e --arg id "${THREAD_ID}" \
    '.type == "session_meta" and .payload.id == $id' >/dev/null; then
    echo "Native Codex rollout header does not match the bound thread." >&2
    exit 1
  fi
fi

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
  cp --preserve=mode,timestamps "${CODEX_ROLLOUT}" "${BACKUP_DIR}/codex-rollout.jsonl"
fi

for memory_scope in workspace-memory repo-memory; do
  if [[ "${memory_scope}" == workspace-memory ]]; then
    memory_root="$(jq -er '.agents.defaults.workspace' "${CONFIG_FILE}")"
  else
    memory_root="${ROOT}"
  fi
  if [[ -d "${memory_root}/memory" ]]; then
    tar -czf "${BACKUP_DIR}/${memory_scope}.tar.gz" -C "${memory_root}" memory
  fi
done
chmod 600 "${BACKUP_DIR}"/*

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
printf 'native_codex_rollout=%s\n' "$(if [[ -n "${CODEX_ROLLOUT}" ]]; then printf present; else printf absent; fi)"
