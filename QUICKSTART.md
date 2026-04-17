# Quickstart

This is the shortest working path for a fresh machine or a fresh AI agent.

## 1. Bootstrap

```bash
/home/OpenClaw/scripts/bootstrap-openclaw.sh
```

This bootstrap sets:

- workspace: `/home/OpenClaw/workspace`
- primary model floor: `codex-cli/gpt-5.4`
- gateway mode: `local`
- gateway bind: `loopback`

Before running agent turns, confirm Codex CLI auth:

```bash
codex login status
```

## 2. Validate

```bash
/home/OpenClaw/scripts/validate-local-setup.sh
```

This validation also confirms the seeded workspace context files exist before first chat or channel setup.

## 3. Run

```bash
/home/OpenClaw/bin/openclaw-local
```

For an always-on server, install the reboot-persistent systemd gateway service:

```bash
/home/OpenClaw/scripts/install-gateway-systemd.sh
/home/OpenClaw/scripts/gateway-systemd-status.sh
/home/OpenClaw/bin/openclaw-local gateway probe
```

If systemd is unavailable, use the tmux fallback:

```bash
/home/OpenClaw/scripts/start-gateway-tmux.sh
/home/OpenClaw/scripts/gateway-tmux-status.sh
/home/OpenClaw/bin/openclaw-local gateway probe
```

Minimal live checks:

```bash
/home/OpenClaw/bin/openclaw-local health
codex exec --model gpt-5.4 --skip-git-repo-check --sandbox workspace-write --color never --json "reply with exactly: codex-ok"
```

## 4. Memory

- durable notes go into `memory/decisions.md`, `memory/active-context.md`, or a project note
- ad hoc captures go into `memory/inbox/`
- use `bin/memory-find` for quick retrieval

## 5. Repo Rules

- do not commit `.openclaw/`
- do not commit `.openclaw-home/`
- keep `/home/OpenClaw/workspace` as the default agent workspace
- keep Markdown as the default memory backend unless there is a concrete reason to introduce semantic retrieval

## 6. Canonical Repo

```bash
git remote add origin https://github.com/SELLSYSTEMS/openclaw-agent-forge.git
```

## 7. Telegram Test Prep

Read [docs/telegram-test-plan.md](docs/telegram-test-plan.md) before wiring a test bot.

Important rule:

- keep the seeded workspace context intact before Telegram is connected
- the bot should already know the host basics before the first DM
