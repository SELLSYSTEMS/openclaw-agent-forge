# AGENTS.md

These instructions are for future AI agents working in `/home/OpenClaw`.

## Goal

Keep this repository as the reproducible source of truth for installing and operating a local isolated OpenClaw setup.

## Non-Negotiable Rules

1. Do not commit `.openclaw/` or `.openclaw-home/`.
2. Always run OpenClaw through the local launcher: `/home/OpenClaw/bin/openclaw-local`.
3. Always keep `OPENCLAW_HOME=/home/OpenClaw/.openclaw-home`.
4. Keep the default agent workspace at `/home/OpenClaw/workspace`.
5. Treat `/home/OpenClaw/memory` as the local memory source of truth.
6. Use Markdown files first. Do not introduce a vector database unless keyword search has clearly stopped being enough.

## Required Flow

1. Read [README.md](README.md), [docs/install-runbook.md](docs/install-runbook.md), and [docs/lessons-learned.md](docs/lessons-learned.md).
2. If OpenClaw is not installed yet, run `scripts/bootstrap-openclaw.sh`.
3. Validate the setup with `scripts/validate-local-setup.sh`.
4. If you change the operating model, update the docs in the same commit.

## Pitfalls Already Seen

- A local prefix install is safer than a global install when multiple agents share the machine.
- `OPENCLAW_HOME` must be isolated or OpenClaw state collides with other sessions.
- Local Markdown memory is the lower-risk default. Obsidian is optional as a UI on top of it.
- Helper scripts should be smoke-tested after creation. One early `printf` bug created a partial note file.
- If shell commands fail with `bwrap: Failed to make / slave: Permission denied`, rerun the required command with escalation instead of debugging the project itself.
