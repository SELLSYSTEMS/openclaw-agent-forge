# Agent Topology

This document records how future agents should rediscover the live agent layout safely instead of trusting stale copied examples.

## Dynamic-first rule

Do not treat another instance's tab names, root paths, or tab order as durable truth.
This repo may include tracked host examples, but future agents must rediscover the live topology on the current machine before acting.

## Discovery Rule

Future agents should not rely on static assumptions.

Use these first:

```bash
<REPO_ROOT>/scripts/agent-landscape.sh
ps -ef | rg -i 'codex|openclaw|node-red|tmux'
tmux ls
```

Then inspect the live targets directly if needed.

## Same-tab live control

If the user wants OpenClaw to type into an already-running neighboring agent tab that is visible in the webterminal, use the live PTY path we tested.

Do it in this order:

1. resolve the target tab or working directory from `/opt/claude-vnc-terminal/data/terminal-state.json`
2. resolve the live PTY from `/proc/<pid>/cwd`, `/proc/<pid>/fd/0`, and `/proc/<pid>/cmdline`
3. write the exact text or command to that `/dev/pts/N`

Canonical helpers in this repo:

```bash
scripts/find-live-terminal.py --tab-name <tab-name> --json
scripts/write-live-terminal.sh --tab-name <tab-name> -- 'echo "hello"'
```

Important rules:

- do not substitute OpenClaw TUI for same-tab neighboring-agent control
- do not use `/codex resume` when the requirement is to affect the already-visible tab
- do not spawn a replacement agent or hide the action in a side channel
- if multiple PTY candidates exist for one cwd, stop and inspect instead of guessing

## Webterminal Context

This environment is commonly accessed through a browser webterminal.

Important rule:

- the exact webterminal URL is instance-specific
- different instances can use different domains or paths
- the public repo should document the pattern, not hardcode the live URL

Recommended local-only file:

- `<REPO_ROOT>/workspace/WEBTERMINAL.local.md`

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
