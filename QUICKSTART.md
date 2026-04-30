# Quickstart

This is the shortest working path for a fresh machine or a fresh AI agent.

## 0. Detect Canonical Owner Root First

Before bootstrap:

- detect `whoami`
- detect `pwd`
- detect `$HOME`
- detect whether a valid OpenClaw repo/install already exists in this owner context
- choose one canonical repo/install root
- do not create duplicate roots such as `/home/OpenClaw` and `/home/openclaw`

Reference paths below reflect this tracked host. On another host, use the same repo-local pattern under that host's canonical owner root.

## 1. Bootstrap

```bash
./scripts/bootstrap-openclaw.sh
```

This bootstrap sets:

- workspace: `<REPO_ROOT>/workspace`
- primary model floor: `gpt-5.4` with Codex CLI as the intended backend path
- gateway mode: `local`
- gateway bind: `loopback`

Before running agent turns, confirm Codex CLI auth:

```bash
codex login status
```

## 2. Validate

```bash
./scripts/validate-local-setup.sh
```

This validation also confirms the seeded workspace context files exist before first chat or channel setup.

## 3. Run

```bash
./bin/openclaw-local
```

For an always-on server, install the reboot-persistent systemd gateway service:

```bash
./scripts/install-gateway-systemd.sh
./scripts/gateway-systemd-status.sh
./bin/openclaw-local gateway probe --timeout 20000
```

If systemd is unavailable, use the tmux fallback:

```bash
./scripts/start-gateway-tmux.sh
./scripts/gateway-tmux-status.sh
./bin/openclaw-local gateway probe --timeout 20000
```

Minimal live checks:

```bash
./bin/openclaw-local health
codex exec --model gpt-5.4 --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox --color never --json "reply with exactly: codex-ok"
```

## 4. Memory

- durable notes go into `memory/decisions.md`, `memory/active-context.md`, or a project note
- ad hoc captures go into `memory/inbox/`
- use `bin/memory-find` for quick retrieval

## 5. Repo Rules

- do not commit `.openclaw/`
- do not commit `.openclaw-home/`
- keep the repo-local `workspace/` as the default agent workspace
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
- for the Telegram-paired installer prompt, `TELEGRAM_BOT_TOKEN` and `TELEGRAM_USER_ID` are mandatory from the start
- if either is missing, stop before install/bootstrap actions
- if token validation or pairing fails, stop immediately and report the exact cause
