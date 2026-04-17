# OpenClaw Agent Forge

Codex-built bootstrap for a live OpenClaw AI server and multi-agent operating environment.

This repository captures a reproducible local OpenClaw installation pattern, the operating notes behind it, and the guardrails for future AI agents.

## What This Repository Tracks

- local launchers and helper scripts
- a bootstrap path for a fresh machine
- local memory structure and durable notes
- a Codex CLI-backed default model path without `OPENAI_API_KEY`
- tmux helpers for keeping the local gateway alive
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
- [docs/telegram-test-plan.md](docs/telegram-test-plan.md) - Telegram prerequisites and approval flow
- [bin/openclaw-local](bin/openclaw-local) - launcher with isolated `OPENCLAW_HOME`
- [scripts/bootstrap-openclaw.sh](scripts/bootstrap-openclaw.sh) - fresh setup bootstrap
- [scripts/validate-local-setup.sh](scripts/validate-local-setup.sh) - smoke-test and validation
- [scripts/start-gateway-tmux.sh](scripts/start-gateway-tmux.sh) - keep the gateway alive without systemd
- [.github/workflows/smoke-check.yml](.github/workflows/smoke-check.yml) - repo sanity checks on GitHub Actions
- [memory/](memory/) - local Markdown memory vault

## Local Layout After Bootstrap

- `.openclaw/` - local OpenClaw installation prefix
- `.openclaw-home/` - isolated runtime home
- `workspace/` - default agent workspace
- `memory/` - local Markdown memory vault

## Bootstrap

```bash
/home/OpenClaw/scripts/bootstrap-openclaw.sh
```

## Validate

```bash
/home/OpenClaw/scripts/validate-local-setup.sh
```

## Run

```bash
/home/OpenClaw/bin/openclaw-local
```

## Model Path

This setup is pinned to `codex-cli/gpt-5.4`.

- OpenClaw delegates agent turns to the installed `codex` CLI.
- Auth stays under the Codex CLI login state instead of this repo managing `OPENAI_API_KEY`.
- The gateway is configured for `local` mode on loopback and can be kept alive with tmux when systemd user services are unavailable.

## Positioning

This repo is not the OpenClaw product source tree.

It is the operator repo around OpenClaw:

- bootstrap scripts
- isolated runtime layout
- memory conventions
- multi-agent workspace defaults
- installation lessons so the next AI agent does not repeat setup mistakes

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
