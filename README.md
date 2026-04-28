# OpenClaw Agent Forge

Codex-built bootstrap for a live OpenClaw AI server and multi-agent operating environment.

This repository captures a reproducible local OpenClaw installation pattern, the operating notes behind it, and the guardrails for future AI agents.

## What This Repository Tracks

- local launchers and helper scripts
- a bootstrap path for a fresh machine
- seeded first-run workspace knowledge so OpenClaw does not start as a blank slate
- local memory structure and durable notes
- a Codex CLI-backed default model path without `OPENAI_API_KEY`
- systemd and tmux helpers for keeping the local gateway alive
- Telegram test-channel preparation notes
- lessons learned from the first installation pass

Published repository:

- `https://github.com/SELLSYSTEMS/openclaw-agent-forge`

It does not track the installed runtime or mutable state directories.
It must also stay free of secrets because the repository is public.

## Repository Layout

- [AGENTS.md](AGENTS.md) - instructions for future AI agents
- [QUICKSTART.md](QUICKSTART.md) - shortest path for a fresh operator or AI agent
- [docs/install-runbook.md](docs/install-runbook.md) - step-by-step installation model
- [docs/lessons-learned.md](docs/lessons-learned.md) - mistakes and decisions worth preserving
- [docs/shared-host-context.md](docs/shared-host-context.md) - safe map of shared Codex, Node-RED, and host-level context
- [docs/agent-topology.md](docs/agent-topology.md) - known agent folders, roles, and rediscovery rules
- [docs/codex-cli-tui.md](docs/codex-cli-tui.md) - how the shared OpenAI Codex CLI TUI works on this host
- [docs/orchestrator-roadmap.md](docs/orchestrator-roadmap.md) - recommended direction for orchestration, TUI, and cross-agent visibility
- [docs/prompt-patterns.md](docs/prompt-patterns.md) - starter prompts for future agents on this host
- [docs/telegram-test-plan.md](docs/telegram-test-plan.md) - Telegram prerequisites and approval flow
- [workspace/MEMORY.md](workspace/MEMORY.md) - seeded public-safe memory for future installs and agents
- [workspace/BOOTSTRAP.md](workspace/BOOTSTRAP.md) - first-run behavior that assumes seeded context already exists
- [bin/openclaw-local](bin/openclaw-local) - launcher with isolated `OPENCLAW_HOME`
- [scripts/agent-landscape.sh](scripts/agent-landscape.sh) - safe status snapshot of shared agents and services
- [scripts/bootstrap-openclaw.sh](scripts/bootstrap-openclaw.sh) - fresh setup bootstrap
- [scripts/install-gateway-systemd.sh](scripts/install-gateway-systemd.sh) - install the boot-persistent systemd gateway service
- [scripts/gateway-systemd-status.sh](scripts/gateway-systemd-status.sh) - inspect the systemd-managed gateway
- [scripts/validate-local-setup.sh](scripts/validate-local-setup.sh) - smoke-test and validation
- [scripts/start-gateway-tmux.sh](scripts/start-gateway-tmux.sh) - fallback gateway runtime when systemd is unavailable
- [systemd/openclaw-gateway.service](systemd/openclaw-gateway.service) - tracked system service for reboot persistence
- [.github/workflows/smoke-check.yml](.github/workflows/smoke-check.yml) - repo sanity checks on GitHub Actions
- [memory/](memory/) - local Markdown memory vault

## Local Layout After Bootstrap

- `.openclaw/` - local OpenClaw installation prefix
- `.openclaw-home/` - isolated runtime home
- `workspace/` - default agent workspace
- `memory/` - local Markdown memory vault

## Canonical Owner Root Rule

This repo documents one installation pattern, but the installer agent must still detect the real owner context it is running from.

- do not blindly clone or install into a second path just because another host used `/home/OpenClaw`
- detect the real owner root from `whoami`, `pwd`, `$HOME`, and the current project/session context
- choose one canonical repo/install root and stay consistent
- do not create duplicate parallel roots such as `/home/OpenClaw` vs `/home/openclaw`

Reference paths in this repo are examples from the current tracked host, not universal commands for every other machine.

## Bootstrap

```bash
./scripts/bootstrap-openclaw.sh
```

## Validate

```bash
./scripts/validate-local-setup.sh
```

## Run

```bash
./bin/openclaw-local
```

## Model Path

This setup uses `gpt-5.5` as the current minimum baseline, with Codex CLI as the intended backend path and `xhigh` reasoning inherited from the shared Codex user config.

- OpenClaw delegates agent turns to the installed `codex` CLI.
- Auth stays under the Codex CLI login state instead of this repo managing `OPENAI_API_KEY`.
- The gateway is configured for `local` mode on loopback and should be kept alive through the repo-managed systemd service on always-on servers.
- The tmux launcher remains a fallback when systemd is unavailable.
- If the shared Codex user default later moves to a numerically newer GPT model than 5.5, OpenClaw should be updated to follow that newer model after a local validation pass.

## Positioning

This repo is not the OpenClaw product source tree.

It is the operator repo around OpenClaw:

- bootstrap scripts
- isolated runtime layout
- memory conventions
- multi-agent workspace defaults
- installation lessons so the next AI agent does not repeat setup mistakes
- shared-host context so OpenClaw can coexist with other long-running agents and Node-RED automations

## Telegram Pairing Input

The installer prompt may begin with:

- `TELEGRAM_BOT_TOKEN="..."`
- `TELEGRAM_USER_ID="..."`

Rules:

- for the Telegram-paired installer prompt, both are mandatory inputs
- the token must stay in local-only runtime secrets or local config
- do not commit Telegram secrets or owner-specific IDs into Git
- if either input is missing, stop before install/bootstrap actions
- if token validation or pairing fails, stop immediately and report the exact problem instead of pretending the install is complete

## Shared Host Context

This machine has more than one active AI system.

- OpenClaw owns the canonical repo-local root for that host; on this tracked machine the canonical root is `/home/OpenClaw`
- the host also has a shared Codex CLI home under `/root/.codex`
- Node-RED runs locally under `/root/.node-red` and should be treated as shared host infrastructure available to all agents
- multiple terminal-driven Codex agents may already be active at the same time

The repo documents those relationships in a public-safe way. It should capture paths, rules, and operating patterns, but never passwords, tokens, or owner-specific identifiers.

## Canonical Remote

```bash
git remote add origin https://github.com/SELLSYSTEMS/openclaw-agent-forge.git
```

## Memory Strategy

The current best-practice default is file-based local memory in Markdown.

- It is transparent and local.
- It is easy for agents to inspect directly.
- It is easy to diff and back up.
- It avoids premature dependence on a vector service.

Obsidian is optional as a UI over the same folder. A vector database should be introduced only when the note corpus is large enough that keyword search is no longer effective.
