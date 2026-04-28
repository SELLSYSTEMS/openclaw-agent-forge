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
- On this host class, assume Node-RED is already installed and shared across agents even if its default flows are empty.
- Never copy Node-RED passwords, hashes, or credential material into tracked repo files.

### OpenClaw

- Repo-local launcher lives under the canonical repo root (tracked host example: `/home/OpenClaw/bin/openclaw-local`)
- Repo-local runtime home lives under the canonical repo root
- Repo-local workspace lives under the canonical repo root
- Repo-local memory lives under the canonical repo root
- Default model floor: `gpt-5.5` with Codex CLI as the intended backend path

## Discovery

- Shared landscape snapshot: `<REPO_ROOT>/scripts/agent-landscape.sh`
- Active processes: `ps -ef | rg -i 'codex|openclaw|node-red|tmux'`
- tmux sessions: `tmux ls`
- OpenClaw health: `<REPO_ROOT>/bin/openclaw-local health`
- OpenClaw gateway probe: `<REPO_ROOT>/bin/openclaw-local gateway probe`

- Treat `/opt/claude-vnc-terminal/data/terminal-state.json` as primary live evidence for which tabs and neighboring agents exist on this host class.
- Do not trust cached webterminal tab names/order during orchestration; reread `/opt/claude-vnc-terminal/data/terminal-state.json` (and, if needed, take a fresh UI snapshot) before steering a live tab.
- Do not conclude "there are no other agents" from OpenClaw session state alone; distinguish OpenClaw sessions, webterminal tabs, neighboring terminal agents, and spawned subagents.
- Tab names and working directories are instance-specific. Derive the target from the live host instead of copying stale paths literally.
- Apply any control contract only after you have detected the actual target agent root on the current machine.
- If one shell surface is constrained, use the tab registry and shared-host docs before you speculate.
- On a VPS/virtual instance, do not default to Docker/container deployment advice unless live inspection actually finds Docker in the stack.
- If `claude-vnc-terminal.service` restarts, expect all webterminal-backed Codex tabs to relaunch; restore the needed Codex conversation with `/resume` so the last session context is recovered after the restart. Be conservative: better to run `/resume` twice and verify you are back on the intended thread than to accidentally create a fresh session and lose continuity.
- Known current agent roots:
  - `/home/admin` → Default AI
  - `/home/langchain` → learnLangChain
  - `/home/udacity` → learnUdacity
  - tracked host example: `/home/OpenClaw` → OpenClaw
- If present, read `WEBTERMINAL.local.md` for the current instance's browser-terminal entrypoint.


## Messaging / File Delivery Rules

- When the user asks for a file in chat, attach the file immediately in the reply using a safe relative `MEDIA:` path; do not answer with only a server-side filesystem path.
- Keep one canonical installer prompt file; do not create duplicate prompt files/variants unless the user explicitly asks for a separate version.
- For the OpenClaw installer prompt, keep Telegram pairing placeholders (`TELEGRAM_BOT_TOKEN`, `TELEGRAM_USER_ID`) in the single canonical prompt and keep owner-context detection / duplicate-root prevention aligned with the repo docs.

## Collaboration Rules

- `docs/` is the public-safe knowledge base for humans and future agents.
- `memory/` holds durable local operating notes.
- Keep secrets and owner-specific identifiers only in ignored local files such as `workspace/*.local.md` or `.openclaw-home/secrets/`.
- If you need to bridge systems, prefer Node-RED or explicit CLI bridges over hidden ad hoc state.
