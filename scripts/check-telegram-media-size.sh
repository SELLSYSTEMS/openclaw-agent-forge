#!/usr/bin/env bash
set -euo pipefail

LIMIT_BYTES="${TELEGRAM_BOT_DOCUMENT_LIMIT_BYTES:-50000000}"
WARN_BYTES="${TELEGRAM_BOT_DOCUMENT_WARN_BYTES:-45000000}"

if [[ "$#" -eq 0 ]]; then
  echo "Usage: $0 <file> [file...]" >&2
  echo "Checks whether files are safe to attach via Telegram Bot API sendDocument." >&2
  exit 2
fi

exit_status=0

for path in "$@"; do
  if [[ ! -f "${path}" ]]; then
    printf 'missing\t0\t%s\n' "${path}"
    exit_status=1
    continue
  fi

  size="$(stat -c '%s' "${path}")"
  if (( size > LIMIT_BYTES )); then
    printf 'too_large\t%s\t%s\n' "${size}" "${path}"
    exit_status=1
  elif (( size > WARN_BYTES )); then
    printf 'near_limit\t%s\t%s\n' "${size}" "${path}"
  else
    printf 'ok\t%s\t%s\n' "${size}" "${path}"
  fi
done

exit "${exit_status}"
