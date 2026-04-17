# MEMORY.md

This is the seeded long-term memory for the OpenClaw workspace.

It is intentionally public-safe and high signal, so a future install or future agent starts with the right operating assumptions from the beginning.

This file is meant to be understood before the first external user conversation and before connecting Telegram or other channels.

## Core Operating Facts

- OpenClaw owns `/home/OpenClaw`
- OpenClaw runtime home is `/home/OpenClaw/.openclaw-home`
- OpenClaw default workspace is `/home/OpenClaw/workspace`
- OpenClaw current model floor is `codex-cli/gpt-5.4`
- OpenClaw should prefer `xhigh` reasoning through the shared Codex user config
- If the shared Codex user model becomes numerically newer than 5.4, OpenClaw should follow it after validation
- OpenClaw should reuse the installed Codex CLI login rather than defaulting to `OPENAI_API_KEY`
- The initial user should not have to reteach the host basics that are already seeded here

## Shared Host Facts

- Shared Codex CLI state lives under `/root/.codex`
- Shared Node-RED state lives under `/root/.node-red`
- Node-RED should be treated as installed and shared by default on this host class, even when the initial flows are sparse
- Multiple Codex agents can run in parallel on the same machine
- The OpenAI Codex CLI TUI is the default interactive Codex mode; `codex` starts it
- The Codex TUI ships with the `codex` CLI; there is no separate server-side TUI package to install
- The real prerequisite is a working `codex` binary on `PATH` plus valid `~/.codex` login state for the Unix account running the session
- On this host class, webterminal tabs share the same Unix user and the same `~/.codex` state
- In browser terminals, prefer `codex --no-alt-screen`

## Known Current Agent Roots

- `/home/admin` → Default AI
- `/home/langchain` → learnLangChain
- `/home/udacity` → learnUdacity
- `/home/OpenClaw` → OpenClaw

Additional tabs or agents may appear later. Do not assume this list is complete forever.

## Webterminal Facts

- Browser access commonly happens through an instance-specific webterminal URL
- The exact live URL belongs in `WEBTERMINAL.local.md`, not in tracked Git files
- The current webterminal implementation is `/opt/claude-vnc-terminal`
- Server-side tab state is persisted in `/opt/claude-vnc-terminal/data/terminal-state.json`
- That state file is the fastest way to discover live tabs, their names, working directories, and providers

## Orchestrator Rules

- Treat OpenClaw as the main orchestrator for `/home/OpenClaw`
- Prefer Node-RED for durable automations, human-readable schemes, collaboration materials, and bridge flows
- Prefer local repo docs, workspace files, and CLI overrides over mutating the global Codex CLI config under `/root/.codex`
- Prefer the repo-managed systemd gateway service for reboot persistence; treat tmux as a fallback only
- Keep public GitHub docs safe for humans and future agents; keep secrets and instance-private identifiers only in ignored local files

## Discovery First

Before making assumptions, use:

```bash
/home/OpenClaw/scripts/agent-landscape.sh
```

Then, if needed:

```bash
ps -ef | rg -i 'codex|openclaw|node-red|tmux'
tmux ls
cat /opt/claude-vnc-terminal/data/terminal-state.json
```

## Telegram

- Telegram is configured via a local token file, not tracked repo secrets
- Owner access is meant to live in local runtime config, not public docs
- Transport is working; do not move secrets or owner-specific IDs into Git

## TUI Status

- The official operator surface is `openclaw-local tui`
- It starts and reaches the gateway
- It can still hit a local device-pairing or operator-approval blocker before becoming fully usable
- Treat that as a gateway authorization issue, not as a failure of the TUI itself
- The other terminal agents use the OpenAI Codex CLI TUI, not the OpenClaw TUI
- Shared Codex CLI behavior and flags are documented in `docs/codex-cli-tui.md`

## Public-Safe Memory Rule

Promote these kinds of facts into tracked memory:

- paths
- architecture decisions
- discovery methods
- operating rules
- bridge patterns

Do not promote:

- tokens
- passwords
- owner-specific IDs
- instance-private URLs
- private transcripts
