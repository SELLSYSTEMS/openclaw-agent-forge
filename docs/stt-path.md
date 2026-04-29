# Local STT Path

This repo defines a local speech-to-text validation path for OpenClaw installs that need audio or voice input.

## Rule

If no verified STT path already exists on the target host, the installer must run:

```bash
./scripts/setup-local-stt.sh
```

Before declaring audio/STT ready, the installer must transcribe a real sample file:

```bash
./scripts/transcribe-local.sh /path/to/sample.wav
```

## Implementation

The default local path uses a repo-local Python virtual environment under:

- `.openclaw-stt/`

The setup script installs a local STT runner there. The transcribe script uses that environment and writes text to stdout.

## Privacy

Do not commit audio samples or transcripts unless they are explicitly public-safe fixtures.

Instance-private audio belongs in local-only scratch paths or runtime state.

## Failure Rule

If setup or transcription fails, report the exact command and error. Do not claim STT is ready.
