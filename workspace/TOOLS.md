# TOOLS.md - Local Notes

This file is the safe machine-context cheat sheet for this workspace.

## Shared Host Services

### Codex CLI

- Global Codex CLI home: `/root/.codex`
- Useful read-first files:
  - `/root/.codex/config.toml`
  - `/root/.codex/history.jsonl`
  - `/root/.codex/logs_2.sqlite`
  - `/root/.codex/state_5.sqlite`
- Treat `/root/.codex` as shared infrastructure.
- Do not rewrite global Codex config unless the user explicitly asks.
- Prefer per-project instructions, local repo docs, and CLI overrides such as `codex -c ...` when you need local behavior.

### Node-RED

- Node-RED home: `/root/.node-red`
- Useful read-first files:
  - `/root/.node-red/settings.js`
  - `/root/.node-red/flows.json`
  - `/root/.node-red/package.json`
- Local inspection shows:
  - `flowFile: flows.json`
  - `flowFilePretty: true`
  - `adminAuth` is configured
  - `editorTheme.projects` is configured
- Treat Node-RED as the preferred place for durable automations, service bridges, and human-readable flow diagrams.
- Never copy Node-RED passwords, hashes, or credential material into tracked repo files.

### OpenClaw

- Repo-local launcher: `/home/OpenClaw/bin/openclaw-local`
- Repo-local runtime home: `/home/OpenClaw/.openclaw-home`
- Repo-local workspace: `/home/OpenClaw/workspace`
- Repo-local memory: `/home/OpenClaw/memory`
- Default model path: `codex-cli/gpt-5.4`

## Discovery

- Shared landscape snapshot: `/home/OpenClaw/scripts/agent-landscape.sh`
- Active processes: `ps -ef | rg -i 'codex|openclaw|node-red|tmux'`
- tmux sessions: `tmux ls`
- OpenClaw health: `/home/OpenClaw/bin/openclaw-local health`
- OpenClaw gateway probe: `/home/OpenClaw/bin/openclaw-local gateway probe`

## Collaboration Rules

- `docs/` is the public-safe knowledge base for humans and future agents.
- `memory/` holds durable local operating notes.
- Keep secrets and owner-specific identifiers only in ignored local files such as `workspace/*.local.md` or `.openclaw-home/secrets/`.
- If you need to bridge systems, prefer Node-RED or explicit CLI bridges over hidden ad hoc state.
