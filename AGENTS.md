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
2. Always run OpenClaw through the repo-local launcher: `<REPO_ROOT>/bin/openclaw-local`.
3. Always keep `OPENCLAW_HOME=<REPO_ROOT>/.openclaw-home`.
4. Keep the default agent workspace at `<REPO_ROOT>/workspace`.
5. Treat `<REPO_ROOT>/memory` as the local memory source of truth.
6. Use Markdown files first. Do not introduce a vector database unless keyword search has clearly stopped being enough.
7. Keep the primary model floor on `gpt-5.4` with Codex CLI as the intended backend path and `xhigh` reasoning as the minimum default. If the shared Codex user default moves to a numerically newer GPT model than 5.5 and is validated locally, OpenClaw should follow that newer model.
8. Do not introduce `OPENAI_API_KEY` as the auth or execution path for normal OpenClaw installs on this host class. Reuse the installed Codex CLI login instead.
9. Do not introduce cron-based automation or scheduled jobs unless the user explicitly asked for cron.
10. For durable automations, scheduled flows, or bridges, prefer the local shared Node-RED under `/root/.node-red`, not cron.
11. Treat this repository as public. Never commit bot tokens, API keys, gateway tokens, or private chat data.
12. Keep machine-local secrets under ignored paths such as `<REPO_ROOT>/.openclaw-home/secrets/`.

## Required Flow

1. Read [README.md](README.md), [docs/install-runbook.md](docs/install-runbook.md), [docs/lessons-learned.md](docs/lessons-learned.md), and [docs/codex-cli-tui.md](docs/codex-cli-tui.md).
2. Read [docs/shared-host-context.md](docs/shared-host-context.md), [docs/agent-topology.md](docs/agent-topology.md), and [docs/orchestrator-roadmap.md](docs/orchestrator-roadmap.md) before changing operating assumptions about the host.
3. Read [workspace/README.md](workspace/README.md) and [workspace/MEMORY.md](workspace/MEMORY.md) before changing workspace defaults or identity prompts.
4. Read [docs/github-publish.md](docs/github-publish.md) before changing repository identity or publication flow.
5. If OpenClaw is not installed yet, run `scripts/bootstrap-openclaw.sh`.
6. Validate the setup with `scripts/validate-local-setup.sh`.
7. If you change the operating model, update the docs in the same commit.

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
- The Codex TUI is already built into `codex`; do not invent a separate server-side TUI install step for it. In browser terminals, prefer `codex --no-alt-screen`.
- If the user wants a message or command to appear in an already-running neighboring webterminal tab, use one canonical path only: resolve the target tab from `terminal-state.json`, resolve the live `/dev/pts/N` from `/proc`, and write directly to that PTY. Do not invent alternate control planes.
- The built-in `openclaw gateway install` path expects systemd user services on Linux. On this host class, prefer the repo-managed system service under `systemd/openclaw-gateway.service` for reboot persistence.
- On this host class, install/operator work should start in no-sandbox / danger-full-access execution by default. If local shell/JS commands fail with `bwrap: Failed to make / slave: Permission denied`, that only confirms the rule was violated: stop immediately and move the session to the correct no-sandbox runtime before continuing.

## Shared Host Rules

- Treat `/root/.codex` and `/root/.node-red` as shared infrastructure, not as OpenClaw-owned state.
- Prefer local repo config, workspace files, CLI overrides, and agent docs over mutating global Codex CLI config.
- Treat OpenClaw as the orchestrator for this repo's workflows.
- Prefer Node-RED when you need durable automations, bridges, or human-readable flow diagrams.
- Do not add cron jobs or cron-based scheduling unless the user explicitly asked for cron.
- On always-on servers, prefer the repo-managed systemd gateway service over tmux.
- Use `scripts/agent-landscape.sh` before assuming which agents or services are active on the host.
