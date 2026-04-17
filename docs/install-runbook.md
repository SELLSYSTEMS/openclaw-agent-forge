# Install Runbook

This runbook describes the local isolated OpenClaw installation pattern used in this repository.

## Target Layout

- install prefix: `/home/OpenClaw/.openclaw`
- runtime home: `/home/OpenClaw/.openclaw-home`
- launcher: `/home/OpenClaw/bin/openclaw-local`
- workspace: `/home/OpenClaw/workspace`
- memory vault: `/home/OpenClaw/memory`
- primary model: `codex-cli/gpt-5.4`
- gateway: `local` mode on loopback

## Why This Layout

- avoids collisions with other agents on the same machine
- keeps runtime state out of global home directories
- makes the setup reproducible from a clean checkout
- lets git track only scripts, docs, and memory structure

## Fresh Bootstrap

Run:

```bash
/home/OpenClaw/scripts/bootstrap-openclaw.sh
```

What it does:

1. Installs OpenClaw into `/home/OpenClaw/.openclaw` via the official installer.
2. Creates `/home/OpenClaw/.openclaw-home`.
3. Configures OpenClaw with `OPENCLAW_HOME=/home/OpenClaw/.openclaw-home`.
4. Sets `agents.defaults.workspace` to `/home/OpenClaw/workspace`.
5. Sets the primary model to `codex-cli/gpt-5.4`.
6. Sets `gateway.mode=local`.
7. Sets `gateway.bind=loopback`.
8. Validates the resulting config.

## Authentication Model

This repository prefers Codex CLI reuse over `OPENAI_API_KEY`.

- install and log in to the `codex` CLI
- keep the OpenClaw model ref at `codex-cli/gpt-5.4`
- let OpenClaw delegate turn execution to the installed Codex CLI

This keeps auth ownership with Codex CLI instead of storing OpenAI API credentials inside the OpenClaw repo or config flow.

## Validation

Run:

```bash
/home/OpenClaw/scripts/validate-local-setup.sh
```

Expected outcomes:

- `openclaw-local --version` prints a version
- `openclaw config validate` reports a valid config
- the configured workspace resolves to `/home/OpenClaw/workspace`
- the configured primary model resolves to `codex-cli/gpt-5.4`
- the configured gateway mode resolves to `local`
- the configured gateway bind resolves to `loopback`
- `codex login status` succeeds

## Keeping The Gateway Alive

Preferred local launcher:

```bash
/home/OpenClaw/bin/openclaw-local
```

If systemd user services are not available, keep the gateway alive with tmux:

```bash
/home/OpenClaw/scripts/start-gateway-tmux.sh
/home/OpenClaw/scripts/gateway-tmux-status.sh
```

## Publishable Files

Commit these:

- docs
- scripts
- helper launchers
- memory structure and durable notes

Do not commit these:

- `.openclaw/`
- `.openclaw-home/`
- transient scratch files
- ad hoc inbox captures unless they were curated intentionally
