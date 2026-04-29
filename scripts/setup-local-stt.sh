#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="${ROOT}/.openclaw-stt"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required for local STT setup" >&2
  exit 1
fi

python3 -m venv "${VENV}"
"${VENV}/bin/python" -m pip install --upgrade pip wheel
"${VENV}/bin/python" -m pip install faster-whisper

cat > "${VENV}/README.local.md" <<'EOF'
# Local STT runtime

This directory is local runtime state and must not be committed.

Use:

```bash
./scripts/transcribe-local.sh /path/to/real-sample.wav
```
EOF

echo "Local STT runtime ready at ${VENV}"
echo "Validate with: ${ROOT}/scripts/transcribe-local.sh /path/to/real-sample.wav"
