# Decisions

## 2026-04-13

### Use an isolated local OpenClaw runtime

- Decision: set `OPENCLAW_HOME=/home/OpenClaw/.openclaw-home`
- Why: prevents session, config, and runtime state from colliding with other agents or global CLI state

### Use file-based memory as the primary memory system

- Decision: store memory in local Markdown files under `/home/OpenClaw/memory`
- Why: transparent, local, easy for agents to read, easy to diff, and operationally simpler than a vector database

### Keep Obsidian optional

- Decision: if a GUI is needed later, use Obsidian on the same `memory/` folder
- Why: this keeps one source of truth while adding a human-friendly editor

## 2026-04-17

### Use Codex CLI as the default OpenClaw model path

- Decision: keep `agents.defaults.model.primary=codex-cli/gpt-5.4`
- Why: this reuses the installed Codex CLI login and avoids making `OPENAI_API_KEY` the default auth path

### Keep repo knowledge public-safe and secrets local-only

- Decision: store channel tokens and similar secrets only under ignored local paths such as `/home/OpenClaw/.openclaw-home/secrets/`
- Why: `SELLSYSTEMS/openclaw-agent-forge` is public and should preserve operational knowledge without leaking credentials

### Keep Telegram setup reproducible without tracking credentials

- Decision: document the secret file path pattern and channel setup flow, but never the token itself
- Why: future agents need the procedure and the exact local path model, not the credential
