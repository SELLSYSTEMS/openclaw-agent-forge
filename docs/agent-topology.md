# Agent Topology

This document records the known current agent layout on this server class and how future agents should rediscover it safely.

## Known Current Roots

- `/home/admin` → Default AI
- `/home/langchain` → learnLangChain
- `/home/udacity` → learnUdacity
- `/home/OpenClaw` → OpenClaw

These names and roots are part of the current known topology.

## Discovery Rule

Future agents should not rely only on static assumptions.

Use these first:

```bash
/home/OpenClaw/scripts/agent-landscape.sh
ps -ef | rg -i 'codex|openclaw|node-red|tmux'
tmux ls
```

Then inspect the known roots directly if needed.

## Webterminal Context

This environment is commonly accessed through a browser webterminal.

Important rule:

- the exact webterminal URL is instance-specific
- different instances can use different domains or paths
- the public repo should document the pattern, not hardcode the live URL

Recommended local-only file:

- `/home/OpenClaw/workspace/WEBTERMINAL.local.md`

Use that file for the current instance's browser-terminal URL and any safe local notes about how to access it.

The server-side implementation currently lives here:

- `/opt/claude-vnc-terminal`

The server-side tab/session registry currently lives here:

- `/opt/claude-vnc-terminal/data/terminal-state.json`

That state file is the fastest way to detect which tabs currently exist and which working directory each tab points at.

Operational rule:

- when asked where agents are running, which tab owns a project, or how to steer another agent, check this file before you speculate
- do not rely on OpenClaw session lists alone for cross-tab topology
- if a shell surface is constrained, that is not an excuse to ignore the tab registry
- OpenClaw is expected to understand and supervise neighboring terminal agents when the user asks for orchestration across tabs

Example fields:

- `name`
- `cwd`
- `provider`
- `createdAt`
- `updatedAt`
- `lastActiveAt`

## Boundary Rules

- OpenClaw should treat itself as the main orchestrator for the canonical repo-local owner root
- OpenClaw should understand the neighboring agent roots, live webterminal tabs, and shared host services
- OpenClaw should distinguish between OpenClaw sessions, webterminal tabs, neighboring terminal agents, and spawned subagents
- OpenClaw should not casually rewrite the global Codex CLI config under `/root/.codex`
- Node-RED should be treated as shared server infrastructure that all agents can use
- On a VPS/virtual instance, do not default to Docker/container advice unless live inspection proves that Docker is part of the actual stack
- Public docs should contain structure and rules, not credentials or instance-private URLs
