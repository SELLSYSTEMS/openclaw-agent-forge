# Install Runbook

This runbook describes the local isolated OpenClaw installation pattern used in this repository.

## Canonical Owner Root First

This repo tracks one concrete host layout, but future installer agents must not blindly hardcode that path on every new machine.

Rules:

- detect the real owner context from `whoami`, `pwd`, `$HOME`, and the current project/session root
- if a valid existing install already exists there, treat the work as an idempotent repair/upgrade pass
- choose one canonical repo/install root and keep everything under it
- do not create duplicate near-identical roots such as `/home/OpenClaw` and `/home/openclaw`

For this tracked host, the canonical root is `/home/OpenClaw`.
For future installs, document and use the actual detected `<REPO_ROOT>` on that machine.

## Operator Runtime Must Work First

Do not start bootstrap from a runtime that cannot execute local shell commands.

For fresh installs on this host class, the operator/install session should start in no-sandbox / danger-full-access mode by default.

If local shell or JS execution fails with:

```text
bwrap: Failed to make / slave: Permission denied
```

that is not an OpenClaw bootstrap problem. It is an operator-runtime problem.

Rules:

- stop immediately
- switch the install/operator session to the correct no-sandbox / danger-full-access execution
- only continue once local shell execution actually works
- do not fake host inspection, STT validation, or bootstrap results from a broken bwrap runtime

## Live Topology Discovery Is Mandatory

Do not treat OpenClaw as the only thing on the box.
On this host class, the installer must seed enough knowledge that future agents can rediscover neighboring tabs and agents without the user reteaching it.

The minimum live topology checks are:

- `cat /opt/claude-vnc-terminal/data/terminal-state.json`
- `<REPO_ROOT>/scripts/agent-landscape.sh`
- `ps -ef | rg -i 'codex|openclaw|node-red|tmux'`
- `tmux ls`

Future agents must explicitly distinguish:

- OpenClaw sessions
- webterminal tabs
- neighboring terminal agents in other tabs
- spawned subagents

Rules:

- do not infer "no other agents exist" from OpenClaw session state alone
- do not ignore the tab registry just because one shell surface is constrained
- tab names and working directories are instance-specific; do not hardcode another machine's naming scheme as if it were universal
- derive the real target root from the live host before applying any control contract or path convention
- on a VPS/virtual instance, do not default to Docker/container deployment advice unless the live host evidence shows Docker is actually present and intended
- treat the webterminal tab registry as first-class live evidence, not trivia
- if the user needs OpenClaw to type into an already-running neighboring webterminal tab, use the direct PTY path documented in `docs/agent-topology.md` instead of inventing a TUI-only control story

## Target Layout

- install prefix: `<REPO_ROOT>/.openclaw`
- runtime home: `<REPO_ROOT>/.openclaw-home`
- launcher: `<REPO_ROOT>/bin/openclaw-local`
- workspace: `<REPO_ROOT>/workspace`
- memory vault: `<REPO_ROOT>/memory`
- baseline model: `codex-cli/gpt-5.4`
- preferred reasoning floor: `xhigh`
- gateway: `local` mode on loopback
- embedded Codex runs: no-interruption policy with day-scale agent timeout and CLI watchdog override
- embedded Codex CLI sandbox: explicit no-sandbox fresh and resume args

## Why This Layout

- avoids collisions with other agents on the same machine
- keeps runtime state out of global home directories
- makes the setup reproducible from a clean checkout
- lets git track only scripts, docs, and memory structure

## Fresh Bootstrap

Run:

```bash
./scripts/bootstrap-openclaw.sh
```

What it does:

1. Installs OpenClaw into `<REPO_ROOT>/.openclaw` via the official installer.
2. Creates `<REPO_ROOT>/.openclaw-home`.
3. Configures OpenClaw with `OPENCLAW_HOME=<REPO_ROOT>/.openclaw-home`.
4. Sets `agents.defaults.workspace` to `<REPO_ROOT>/workspace`.
5. Sets the primary model to `codex-cli/gpt-5.4`, or to the shared Codex user model if it is numerically newer than 5.5. If `gpt-5.5` resolves by default, it must be overridden.
6. Sets `agents.defaults.timeoutSeconds=604800`.
7. Sets `agents.defaults.llm.idleTimeoutSeconds=0`.
8. Sets `agents.defaults.contextInjection=continuation-skip` so continuation turns do not keep reinjecting the full bootstrap payload.
9. Sets `agents.defaults.sandbox.mode=off`.
10. Sets explicit `agents.defaults.cliBackends.codex-cli.args` and `resumeArgs` that use `--dangerously-bypass-approvals-and-sandbox` instead of OpenClaw's bundled `--sandbox workspace-write` default.
11. Sets explicit `agents.defaults.cliBackends.codex-cli.output=jsonl` and `resumeOutput=jsonl` because both fresh and resume Codex CLI vectors use `--json`.
12. Sets day-scale `agents.defaults.cliBackends.codex-cli.reliability.watchdog` overrides for both fresh and resume runs.
13. Sets `gateway.mode=local`.
14. Sets `gateway.bind=loopback`.
15. Provisions the repo-local offline STT path via `scripts/setup-local-stt.sh`.
16. Validates the STT path on a real speech sample via `scripts/validate-local-stt.sh`.
17. Validates the resulting config.

After bootstrap or any Codex/OpenClaw upgrade, run:

```bash
scripts/validate-codex-cli-contract.sh
scripts/validate-local-setup.sh
```

The first script exists specifically to catch fresh/resume Codex CLI argument drift before a Telegram turn fails generically.

## Authentication Model

This repository prefers Codex CLI reuse over `OPENAI_API_KEY`.

- install and log in to the `codex` CLI
- keep the OpenClaw model ref at `codex-cli/gpt-5.4` or a newer shared Codex user model when one exists, never `gpt-5.5`
- let OpenClaw delegate turn execution to the installed Codex CLI
- keep shared Codex reasoning at `xhigh`
- do not re-route install/runtime execution through direct API-key auth when Codex CLI reuse is available

This keeps auth ownership with Codex CLI instead of storing OpenAI API credentials inside the OpenClaw repo or config flow.

## No-Interruption Embedded Codex Policy

This host class should not kill serious work just because Codex stays silent while reasoning.

Required baseline:

- `agents.defaults.timeoutSeconds >= 604800`
- `agents.defaults.llm.idleTimeoutSeconds = 0`
- `agents.defaults.contextInjection = continuation-skip`
- `agents.defaults.sandbox.mode = off`
- `agents.defaults.cliBackends.codex-cli.args` uses `--dangerously-bypass-approvals-and-sandbox`, not `--sandbox workspace-write`
- `agents.defaults.cliBackends.codex-cli.resumeArgs` uses `["exec","resume","--json","--dangerously-bypass-approvals-and-sandbox","--skip-git-repo-check","{sessionId}"]`
- `agents.defaults.cliBackends.codex-cli.output = jsonl`
- `agents.defaults.cliBackends.codex-cli.resumeOutput = jsonl`
- `agents.defaults.cliBackends.codex-cli.reliability.watchdog.fresh.noOutputTimeoutMs` set at day scale
- `agents.defaults.cliBackends.codex-cli.reliability.watchdog.resume.noOutputTimeoutMs` set at day scale

Why:

- the OpenClaw gateway can stay healthy while an embedded `codex-cli` turn dies internally
- the stock fresh watchdog floor can kill a quiet turn after about 180 seconds
- the bundled `codex-cli` backend defaults to `--sandbox workspace-write`, which can make every local memory/project-dossier read fail with `bwrap: Failed to make / slave: Permission denied`
- `codex exec resume` does not accept the same flags as fresh `codex exec`; in particular, do not include `--color never` in `resumeArgs`, and keep resume options before `{sessionId}`
- OpenClaw's bundled backend can treat resumed Codex output as plain text; if `resumeArgs` contains `--json` but `resumeOutput` is not `jsonl`, Telegram can receive raw JSONL/tool output/code instead of the final human report
- Telegram then only shows a generic failure even though the project itself did not fail

Do not revert this repo to the stock no-output watchdog behavior.
Do not revert this repo to the bundled `codex-cli` sandbox args on this host class.
Do not make fresh and resume `codex-cli` args identical without checking `codex exec resume --help`.
Do not let `codex-cli` fresh/resume output modes drift away from `jsonl` while the args include `--json`.

## Automation And Scheduling Policy

- Do not add cron jobs, timers, or cron-driven repair loops during normal install/bootstrap unless the user explicitly asked for cron.
- For durable automations, scheduled flows, and bridges on this host class, use the local shared Node-RED runtime under `/root/.node-red`.
- In shared Node-RED, create or use a dedicated new OpenClaw-specific tab/project scope; do not mix OpenClaw flows into unrelated user flows.
- Keep the install path repo-local and CLI-driven; do not add hidden external scheduler dependencies.

## Seeded Workspace Memory

This repository ships a tracked, public-safe workspace memory seed:

- `<REPO_ROOT>/workspace/MEMORY.md`

Future agents should read `workspace/README.md` and `workspace/MEMORY.md` before changing workspace prompts, identity files, or local overrides.

Keep private data out of that tracked seed:

- instance-private URLs belong in `workspace/*.local.md`
- secrets belong in `.openclaw-home/secrets/`
- owner-specific IDs belong in local runtime state, not public Git

## Seeded Knowledge Before First Chat

A fresh OpenClaw install from this repo should **not** behave like a blank slate.

Before the first user message or Telegram connection, the workspace should already contain and preserve these tracked context files:

- `<REPO_ROOT>/workspace/AGENTS.md`
- `<REPO_ROOT>/workspace/MEMORY.md`
- `<REPO_ROOT>/workspace/TOOLS.md`
- `<REPO_ROOT>/workspace/WEBTERMINAL.md`
- `<REPO_ROOT>/workspace/SOUL.md`
- `<REPO_ROOT>/workspace/IDENTITY.md`
- `<REPO_ROOT>/workspace/USER.md`

Behavior rule:

- use those files to preload host knowledge and operating assumptions
- ask only for missing personalization
- do not make the first Telegram DM responsible for teaching the machine basics

Validation should happen before starting the gateway or adding channels.

## Telegram Pairing During Install

If the install prompt includes:

- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_USER_ID`

then Telegram setup is explicitly in scope for that install pass.

Rules:

- for the Telegram-paired installer prompt, both inputs are mandatory from the start
- if either is missing, stop before install/bootstrap actions
- keep the token in local-only secrets or local config
- never commit the token or the owner-specific user ID to Git
- validate the bot token during the install pass
- attempt pairing/verification against `TELEGRAM_USER_ID` during the same pass
- for a normal owner-only Telegram bot on this host class, explicitly set `channels.telegram.execApprovals.enabled=false` unless the install is intentionally setting up Telegram as a native exec-approval client
- do not leave Telegram native exec approvals in implicit `auto` mode during install; approvers can be inferred from `allowFrom` and later trigger `pairing required` loops if no operator client with `operator.approvals` is paired
- if token validation fails or pairing cannot be completed, stop immediately and report the exact issue

## Codex CLI Notes

For generic Codex CLI TUI behavior, auth, and flags, see:

- `docs/codex-cli-tui.md`

This install runbook must not hardcode current-host tab names, neighboring agent roots, or specific project paths from one machine as if they were universal install facts.

## Validation

Run:

```bash
./scripts/validate-local-setup.sh
```

Expected outcomes:

- `scripts/validate-codex-cli-contract.sh` passes
- `openclaw-local --version` prints a version
- `openclaw config validate` reports a valid config
- the configured workspace resolves to `<REPO_ROOT>/workspace`
- the configured primary model resolves to either `codex-cli/<model>` or the current upstream canonical `openai/<model>` plus `agents.defaults.agentRuntime.id=codex-cli`
- the configured gateway mode resolves to `local`
- the configured gateway bind resolves to `loopback`
- `agents.defaults.timeoutSeconds` is at least `604800`
- `agents.defaults.llm.idleTimeoutSeconds` equals `0`
- `agents.defaults.contextInjection` equals `continuation-skip`
- `agents.defaults.sandbox.mode` equals `off`
- the configured `codex-cli` fresh args bypass the Codex CLI sandbox
- the configured `codex-cli` resume args use the resume-specific vector without `--color`
- the configured `codex-cli` fresh and resume no-output watchdog overrides are set at day scale
- `codex login status` succeeds
- the shared Codex reasoning default resolves to `xhigh`
- the repo-local STT venv exists at `<REPO_ROOT>/.venv-stt`
- `faster-whisper` imports successfully from that venv
- `scripts/validate-local-stt.sh` succeeds on a real speech sample
- if Telegram is enabled, Telegram transport must be working before install completion is claimed
- if Telegram is enabled, `channels.telegram.execApprovals.enabled` must be explicit, not implicit `auto`; `false` is the stable default on this host class
- if Telegram is expected to handle voice notes, do not call the install audio-ready until the local STT path is validated and any remaining gap to real inbound voice-note transcription is stated explicitly

## Keeping The Gateway Alive

Preferred local launcher:

```bash
./bin/openclaw-local
```

For an always-on shared Linux server, prefer the repo-managed systemd service:

```bash
./scripts/install-gateway-systemd.sh
./scripts/gateway-systemd-status.sh
```

Why this repo uses a system service:

- OpenClaw's built-in `gateway install` path expects a systemd user service on Linux
- this host class may not have working systemd user services for the shared terminal environment
- a system service under `/etc/systemd/system/openclaw-gateway.service` survives server reboot cleanly

If systemd is unavailable, keep the gateway alive with tmux:

```bash
./scripts/start-gateway-tmux.sh
./scripts/gateway-tmux-status.sh
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
