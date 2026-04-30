#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="${VENV:-$ROOT/.venv-stt}"

if [[ ! -x "$VENV/bin/python" ]]; then
  echo "Local STT venv is missing: $VENV" >&2
  echo "Provisioning repo-local STT now..." >&2
  "$ROOT/scripts/setup-local-stt.sh" >&2
fi

exec "$VENV/bin/python" "$ROOT/scripts/transcribe-local.py" "$@"
