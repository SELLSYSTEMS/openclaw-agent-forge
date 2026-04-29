#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="${VENV:-$ROOT/.venv-stt}"
PYTHON="${PYTHON:-python3}"

if [[ -x "$VENV/bin/python" ]] && "$VENV/bin/python" -c 'import faster_whisper' >/dev/null 2>&1; then
  cat <<EOF
Local STT is ready.

Venv: $VENV
Run:
  $ROOT/scripts/transcribe-local.sh path/to/audio.ogg
EOF
  exit 0
fi

"$PYTHON" -m venv "$VENV"
# shellcheck disable=SC1091
source "$VENV/bin/activate"

python -m pip install --upgrade pip
python -m pip install faster-whisper

cat <<EOF
Local STT is ready.

Venv: $VENV
Run:
  $ROOT/scripts/transcribe-local.sh path/to/audio.ogg
EOF
