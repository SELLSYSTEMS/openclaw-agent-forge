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

## Boundary Rules

- OpenClaw should treat itself as the main orchestrator for `/home/OpenClaw`
- OpenClaw should understand the neighboring agent roots and shared host services
- OpenClaw should not casually rewrite the global Codex CLI config under `/root/.codex`
- Node-RED should be treated as shared server infrastructure that all agents can use
- Public docs should contain structure and rules, not credentials or instance-private URLs
