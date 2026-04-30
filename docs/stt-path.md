# Speech-to-Text Path Notes

See also: `docs/data-sources.md`, `docs/memory-architecture.md`, `docs/installer-capability-contract.md`

This file exists so future agents do not have to relearn the same runtime-surface distinction.

## Core rule

- Treat Telegram/OpenClaw chat turns, webterminal sessions, browser-side flows, and local shell flows as separate runtime surfaces.
- A working media/STT path on one surface does **not** imply the same path exists on another.

## Operator rule

Before claiming transcription support, verify the exact surface:

1. What surface is handling the message? Telegram turn, webterminal, browser tool, or local CLI?
2. Is there a verified STT path for that surface right now?
3. If yes, what implementation provides it?
4. If no, state that the surface currently has no wired STT path.

## Long-term fix

To make this reliable across future instances, wire one canonical STT path for OpenClaw and record it here:

- **Option A:** local/offline STT
- **Option B:** explicit API-backed STT

## Repo-local offline path

Current repo-local offline path:

- setup: `scripts/setup-local-stt.sh`
- use: `scripts/transcribe-local.sh path/to/audio.ogg`
- validate: `scripts/validate-local-stt.sh`
- implementation: `scripts/transcribe-local.py`
- default model: `small`
- default runtime: CPU + `int8`
- installer rule: if no other verified STT path exists, provision this during install/bootstrap and validate it on a real sample before claiming audio is ready

## When the canonical path is implemented, document:

- exact command/tool entrypoint
- which surfaces can use it
- supported formats and limits
- required credentials or local dependencies
- failure mode / fallback wording
- a quick verification checklist

## Current status

- Surface mismatch is a known fact.
- A repo-local offline STT path now exists; surface integration and coverage still need to be wired/validated explicitly.
