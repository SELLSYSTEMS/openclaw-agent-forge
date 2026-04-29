#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="${ROOT}/.openclaw-stt"
INPUT="${1:-}"
MODEL_SIZE="${OPENCLAW_STT_MODEL_SIZE:-tiny.en}"

if [[ -z "${INPUT}" ]]; then
  echo "Usage: $0 /path/to/real-audio-sample" >&2
  exit 2
fi

if [[ ! -f "${INPUT}" ]]; then
  echo "Audio sample not found: ${INPUT}" >&2
  exit 1
fi

if [[ ! -x "${VENV}/bin/python" ]]; then
  echo "Local STT runtime is missing. Run: ${ROOT}/scripts/setup-local-stt.sh" >&2
  exit 1
fi

"${VENV}/bin/python" - "$INPUT" "$MODEL_SIZE" <<'PY'
import sys
from faster_whisper import WhisperModel

audio_path = sys.argv[1]
model_size = sys.argv[2]

model = WhisperModel(model_size, device="cpu", compute_type="int8")
segments, info = model.transcribe(audio_path, beam_size=1)

print(f"# language={info.language} probability={info.language_probability:.3f}")
emitted = False
for segment in segments:
    text = segment.text.strip()
    if text:
        print(text)
        emitted = True

if not emitted:
    raise SystemExit("No speech text was transcribed from the provided sample")
PY
