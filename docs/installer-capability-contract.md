# Installer Capability Contract

The installer/operator agent must prove capability through live checks and repo-managed scripts.

## Required Capabilities

The installer must be able to:

- run shell commands
- read live host state
- inspect `/opt/claude-vnc-terminal/data/terminal-state.json` when present
- run `scripts/agent-landscape.sh`
- inspect processes and tmux sessions
- run Codex CLI checks
- install OpenClaw under one canonical owner root
- validate the gateway and config
- write only local-only secrets for Telegram pairing

## Webterminal Control Priority

When live control of an existing webterminal agent is required, prefer:

1. PTY/WebSocket bridge.
2. tmux bridge.
3. browser UI only as the last resort.

Do not use browser UI setup flows for the installer path.

## Claims The Installer Must Not Make

Do not claim:

- no other agents exist just because OpenClaw session state is sparse
- Docker is part of the architecture without live host evidence
- Telegram pairing is complete without an actual verification against `TELEGRAM_USER_ID`
- STT/audio is ready without transcribing a real sample file
- persistence is clean without checking systemd or the selected fallback runtime

## Sandbox Rule

Installer/operator flows must run with enough filesystem and process visibility to discover the live topology and manage the gateway.

If a sandbox blocks required topology discovery or webterminal control, stop and report the blocked capability instead of guessing.
