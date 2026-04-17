# Orchestrator Roadmap

This document captures the recommended direction for making OpenClaw the main coordinator on a shared AI server without breaking global host state.

## Goal

Make the system understandable for both humans and future AI agents:

- what is running now
- which config belongs to which tool
- how agents can be inspected or interacted with
- where repeatable automations should live
- which knowledge belongs in GitHub versus local-only files

## Current Facts

From local inspection:

- multiple Codex CLI processes can run in parallel on this host
- OpenClaw has its own isolated runtime under `/home/OpenClaw/.openclaw-home`
- Node-RED is already installed and running locally
- the global Codex CLI home lives under `/root/.codex`
- known current agent roots are `/home/admin`, `/home/langchain`, `/home/udacity`, and `/home/OpenClaw`
- browser access commonly happens through an instance-specific webterminal URL
- the current webterminal implementation lives under `/opt/claude-vnc-terminal`
- server-side tab state is persisted in `/opt/claude-vnc-terminal/data/terminal-state.json`

From official docs:

- OpenClaw ships an official terminal UI: `openclaw tui`
- one Gateway can host multiple agents; separate VPSes are usually unnecessary
- there is no built-in bot-to-bot bridge, but a CLI bridge pattern is supported
- Node-RED projects are Git-backed when enabled in `settings.js`

## Recommendation

### 1. Keep OpenClaw As The Main Orchestrator

OpenClaw should remain the coordination layer for this repo because it already owns:

- the local workspace
- the Telegram ingress
- the Codex CLI-backed model path
- the gateway and session model

### 2. Use The Official OpenClaw TUI As The Main Operator Surface

The first TUI to adopt should be the one OpenClaw already ships:

```bash
/home/OpenClaw/bin/openclaw-local tui
```

Why:

- it already understands agents and sessions
- it shows history and streaming tool output
- it avoids inventing a parallel control plane too early

### 3. Use Node-RED For Durable Automations And Bridges

When a workflow needs:

- repeated execution
- message fan-out
- polling or triggers
- a human-readable diagram
- integration glue between systems

prefer Node-RED over hidden ad hoc scripts.

On this host class, agents should assume Node-RED already exists as a shared service instead of treating it as a per-project install step.

### 4. Treat Shared Codex State As Read-First Context

The shared Codex home under `/root/.codex` is useful for host awareness:

- global defaults
- prior session history
- active project roots

But it should not become repo-owned state.

Preferred pattern:

- read and summarize what matters
- store durable repo-specific conclusions in `/home/OpenClaw/docs` or `/home/OpenClaw/memory`
- avoid mutating `/root/.codex/config.toml` unless the user explicitly asks

### 5. Bridge Systems Explicitly

If OpenClaw needs to interact with another bot or service, use explicit bridges:

- `openclaw agent --message ... --deliver`
- Node-RED flows
- explicit scripts with clear ownership

Avoid opaque side effects or hidden cross-tool state.

## Phased Implementation

### Phase 1: Shared Context

Keep these current:

- `docs/shared-host-context.md`
- `workspace/AGENTS.md`
- `workspace/TOOLS.md`
- `memory/active-context.md`
- `memory/decisions.md`

### Phase 2: Discovery

Use:

- `scripts/agent-landscape.sh`
- `tmux ls`
- `ps -ef | rg -i 'codex|openclaw|node-red|tmux'`
- `workspace/WEBTERMINAL.local.md` when present
- `/opt/claude-vnc-terminal/data/terminal-state.json` when present

This gives a fast answer to “what is running now?”

### Phase 3: Operator UI

Adopt the official OpenClaw TUI first:

```bash
/home/OpenClaw/bin/openclaw-local tui
```

Only after that should a custom dashboard or alternate TUI be considered.

### Phase 4: Cross-Agent Visibility

Do not directly couple to raw SQLite internals from `/root/.codex` unless there is no better path.

Prefer:

- history summaries
- safe snapshots
- explicit bridge flows
- Markdown memory updates

### Phase 5: Human Collaboration

Docs should stay understandable for humans:

- architecture docs in `docs/`
- short operational memory in `memory/`
- durable automation in Node-RED

## Research Notes

Official references used here:

- OpenClaw TUI: `https://docs.openclaw.ai/web/tui`
- OpenClaw FAQ on multi-agent and bot-to-bot patterns: `https://docs.openclaw.ai/help/faq`
- Node-RED projects: `https://nodered.org/docs/user-guide/projects/`
- Node-RED runtime configuration: `https://nodered.org/docs/user-guide/runtime/configuration`
