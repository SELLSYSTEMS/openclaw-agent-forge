# AGENTS.md

These instructions are for future AI agents working in `/home/OpenClaw`.

## Goal

Keep this repository as the reproducible source of truth for installing and operating a local isolated OpenClaw setup.

Canonical repository identity:

- Name: `openclaw-agent-forge`
- Meaning: Codex-built bootstrap and operations repo for a live OpenClaw AI server with multi-agent workflows
- GitHub: `https://github.com/SELLSYSTEMS/openclaw-agent-forge`

## Non-Negotiable Rules

1. Do not commit `.openclaw/` or `.openclaw-home/`.
2. Always run OpenClaw through the local launcher: `/home/OpenClaw/bin/openclaw-local`.
3. Always keep `OPENCLAW_HOME=/home/OpenClaw/.openclaw-home`.
4. Keep the default agent workspace at `/home/OpenClaw/workspace`.
5. Treat `/home/OpenClaw/memory` as the local memory source of truth.
6. Use Markdown files first. Do not introduce a vector database unless keyword search has clearly stopped being enough.
7. Keep the primary model on `codex-cli/gpt-5.4` unless the user explicitly asks for a different provider.
8. Do not introduce `OPENAI_API_KEY` as the default auth path when Codex CLI reuse is available.
9. Treat this repository as public. Never commit bot tokens, API keys, gateway tokens, or private chat data.
10. Keep machine-local secrets under ignored paths such as `/home/OpenClaw/.openclaw-home/secrets/`.

## Required Flow

1. Read [README.md](README.md), [docs/install-runbook.md](docs/install-runbook.md), and [docs/lessons-learned.md](docs/lessons-learned.md).
2. Read [docs/shared-host-context.md](docs/shared-host-context.md), [docs/agent-topology.md](docs/agent-topology.md), and [docs/orchestrator-roadmap.md](docs/orchestrator-roadmap.md) before changing operating assumptions about the host.
3. Read [docs/github-publish.md](docs/github-publish.md) before changing repository identity or publication flow.
4. If OpenClaw is not installed yet, run `scripts/bootstrap-openclaw.sh`.
5. Validate the setup with `scripts/validate-local-setup.sh`.
6. If you change the operating model, update the docs in the same commit.

## Pitfalls Already Seen

- A local prefix install is safer than a global install when multiple agents share the machine.
- `OPENCLAW_HOME` must be isolated or OpenClaw state collides with other sessions.
- Local Markdown memory is the lower-risk default. Obsidian is optional as a UI on top of it.
- Helper scripts should be smoke-tested after creation. One early `printf` bug created a partial note file.
- OpenClaw config writes should be applied sequentially, not in parallel, or later writes can clobber earlier ones.
- A healthy gateway probe does not guarantee full operator scope; `pairing required` on admin-style RPCs is a separate gateway authorization issue.
- Telegram channel tokens should be loaded from a local `tokenFile` under `.openclaw-home/secrets`, never from tracked docs or scripts.
- `/root/.codex` is a shared host-level Codex CLI home. Read it first, but do not rewrite global config casually from this repo.
- `/root/.node-red` is a shared host service for automations and diagrams. Treat it as installed/available shared infrastructure, even when flows are still close to empty. Keep passwords, credential material, and user-specific data out of the public repo.
- Browser webterminal access is part of the operating model on this host class, but the exact terminal URL is instance-specific and should stay in local-only notes, not public Git.
- If shell commands fail with `bwrap: Failed to make / slave: Permission denied`, rerun the required command with escalation instead of debugging the project itself.

## Shared Host Rules

- Treat `/root/.codex` and `/root/.node-red` as shared infrastructure, not as OpenClaw-owned state.
- Prefer local repo config, workspace files, CLI overrides, and agent docs over mutating global Codex CLI config.
- Treat OpenClaw as the orchestrator for this repo's workflows.
- Prefer Node-RED when you need durable automations, bridges, or human-readable flow diagrams.
- Use `scripts/agent-landscape.sh` before assuming which agents or services are active on the host.
