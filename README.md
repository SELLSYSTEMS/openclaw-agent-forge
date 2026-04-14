# OpenClaw Local Bootstrap

This repository captures a reproducible local OpenClaw installation pattern, the operating notes behind it, and the guardrails for future AI agents.

## What This Repository Tracks

- local launchers and helper scripts
- a bootstrap path for a fresh machine
- local memory structure and durable notes
- lessons learned from the first installation pass

It does not track the installed runtime or mutable state directories.

## Repository Layout

- [AGENTS.md](AGENTS.md) - instructions for future AI agents
- [docs/install-runbook.md](docs/install-runbook.md) - step-by-step installation model
- [docs/lessons-learned.md](docs/lessons-learned.md) - mistakes and decisions worth preserving
- [bin/openclaw-local](bin/openclaw-local) - launcher with isolated `OPENCLAW_HOME`
- [scripts/bootstrap-openclaw.sh](scripts/bootstrap-openclaw.sh) - fresh setup bootstrap
- [scripts/validate-local-setup.sh](scripts/validate-local-setup.sh) - smoke-test and validation
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

## Memory Strategy

The current best-practice default is file-based local memory in Markdown.

- It is transparent and local.
- It is easy for agents to inspect directly.
- It is easy to diff and back up.
- It avoids premature dependence on a vector service.

Obsidian is optional as a UI over the same folder. A vector database should be introduced only when the note corpus is large enough that keyword search is no longer effective.
