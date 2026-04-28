# MEMORY.md

This is the seeded long-term memory for the OpenClaw workspace.

It is intentionally public-safe and high signal, so a future install or future agent starts with the right operating assumptions from the beginning.

This file is meant to be understood before the first external user conversation and before connecting Telegram or other channels.

## Core Operating Facts

- OpenClaw owns the canonical repo-local root on this host; on the tracked reference host that root is `/home/OpenClaw`
- OpenClaw runtime home is repo-local under the canonical root
- OpenClaw default workspace is repo-local under the canonical root
- OpenClaw current model floor is `gpt-5.5` with Codex CLI as the intended backend path
- OpenClaw should prefer `xhigh` reasoning through the shared Codex user config
- If the shared Codex user model becomes numerically newer than 5.5, OpenClaw should follow it after validation
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
- tracked host example: `/home/OpenClaw` → OpenClaw

Additional tabs or agents may appear later. Do not assume this list is complete forever.

## Webterminal Facts

- Browser access commonly happens through an instance-specific webterminal URL
- The exact live URL belongs in `WEBTERMINAL.local.md`, not in tracked Git files
- The current webterminal implementation is `/opt/claude-vnc-terminal`
- Server-side tab state is persisted in `/opt/claude-vnc-terminal/data/terminal-state.json`
- That state file is the fastest way to discover live tabs, their names, working directories, and providers
- OpenClaw session state is not the same thing as webterminal tab state
- Neighboring terminal agents on other tabs are not the same thing as OpenClaw-spawned subagents
- When an agent needs to understand where other live agents are running, the tab-state file is primary evidence

## Orchestrator Rules

- Treat OpenClaw as the main orchestrator for its canonical repo-local root on the host
- Do not use direct OpenAI API calls from the machine unless the user explicitly approves it
- Prefer local tools, shared Codex login state, and orchestration of existing terminal agents over adding raw API-key based integrations
- Prefer Node-RED for durable automations, human-readable schemes, collaboration materials, and bridge flows
- Prefer local repo docs, workspace files, and CLI overrides over mutating the global Codex CLI config under `/root/.codex`
- Prefer the repo-managed systemd gateway service for reboot persistence; treat tmux as a fallback only
- When reasoning about live topology, inspect the tab-state file and shared-host evidence before speculating
- Tab names and working directories are instance-specific; examples from another host are not universal constants
- If a user shows a control contract from another instance, parameterize it by the detected agent root instead of copying the path literally
- On a VPS/virtual instance, do not default to Docker/container deployment advice unless live inspection proves Docker is actually part of the stack
- Keep public GitHub docs safe for humans and future agents; keep secrets and instance-private identifiers only in ignored local files

## Discovery First

Before making assumptions, use:

```bash
<REPO_ROOT>/scripts/agent-landscape.sh
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
