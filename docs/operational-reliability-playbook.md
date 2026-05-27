# Operational Reliability Playbook

This repo exists because repeated live-agent failures are expensive. Future agents must treat every real incident as a regression class, not as a one-off chat problem.

## Mandatory Incident Loop

When OpenClaw or a connected agent breaks:

1. Identify whether the work failed, delivery failed, or only the user-visible reply failed.
2. Read local memory, project dossiers, git state, and service logs before asking the user to restate context.
3. Write the root cause into tracked docs or seeded workspace memory.
4. Add an executable guardrail when possible.
5. Validate live runtime after the fix.
6. Commit and push the fix so future installs inherit it.

Do not close a recurring incident with documentation only when a script can detect it.

## Failure Classes Already Seen

- `bwrap: Failed to make / slave: Permission denied`: wrong sandbox/runtime. On this host class, OpenClaw embedded Codex must run with `agents.defaults.sandbox.mode=off` and no-sandbox Codex CLI backend args.
- `unexpected argument '--color' found`: fresh and resume Codex CLI args were incorrectly mirrored. `codex exec` accepts `--color`; `codex exec resume` currently does not.
- Generic Telegram failure after long work: can be transport delivery failure, artifact upload limit, or embedded CLI failure. Check logs and local repo state before restarting.
- Long silent tasks killed internally: keep day-scale OpenClaw agent timeout and day-scale `codex-cli` watchdog overrides.
- Raw JSONL/tool/code flood in Telegram after a completed Codex turn: check `agents.defaults.cliBackends.codex-cli.output` and `resumeOutput`. If Codex CLI args include `--json`, both output modes must be `jsonl`; otherwise OpenClaw can treat the whole Codex JSONL stream as a chat reply and hit Telegram `429 Too Many Requests`.
- Repeated unrelated-looking Codex failures while the service remains healthy: check whether the primary model is still `codex-cli/*`. On this host class that is the architectural root cause, because OpenClaw documents CLI backends as fallback/safety-net runtime. Primary runtime must be `codex/*` through the bundled Codex app-server harness.
- Gateway restart during long work at an exact-looking time is not always cron or manual restart. On 2026-05-26 at 04:00 UTC, `openclaw-gateway.service` failed with `result 'oom-kill'` after a child JVM/Gradle/tool process inside the gateway cgroup hit the OOM killer; systemd's default `OOMPolicy=stop` then stopped the whole gateway and silently lost the active Telegram turn. The repo-managed unit must set `OOMPolicy=continue` so a child OOM does not kill the gateway process.
- Telegram media turn fails with `No prompt provided via stdin` after media understanding succeeds: this is a `codex-cli` backend prompt/image delivery failure, not memory loss. Stop patching individual CLI symptoms and migrate the primary runtime to `codex/*` with `agents.defaults.embeddedHarness.runtime=codex`.
- Oversized artifacts: Telegram direct upload can fail for APKs. Run delivery preflight and provide a safe link/path instead of forcing direct attachment.
- `pairing required` on admin-style RPCs: separate gateway authorization issue. Do not confuse it with Telegram health, model auth, or memory loss.
- Parallel OpenClaw config writes: can clobber each other. Apply config writes sequentially.
- Context recovery failure while memory exists: usually runtime access/config failure, not missing knowledge.

## Required Gates

Run these after install, repair, or Codex/OpenClaw upgrade:

```bash
scripts/validate-codex-cli-contract.sh
scripts/validate-codex-harness-contract.sh
scripts/validate-local-setup.sh
```

After any model/runtime change, also run:

```bash
scripts/probe-codex-harness-turn.sh
```

For service state:

```bash
systemctl status openclaw-gateway.service --no-pager
systemctl show openclaw-gateway.service --property=OOMPolicy,KillMode,NRestarts,MemoryCurrent,MemoryPeak --no-pager
bin/openclaw-local health
```

For host topology:

```bash
scripts/agent-landscape.sh
```

## Codex App-Server Harness Contract

The primary Telegram/OpenClaw runtime on this host class must be:

```text
agents.defaults.model.primary=codex/gpt-5.4
plugins.entries.codex.enabled=true
agents.defaults.embeddedHarness.runtime=codex
agents.defaults.embeddedHarness.fallback=pi
agents.defaults.thinkingDefault=xhigh
plugins.entries.codex.config.appServer.sandbox=danger-full-access
```

Use a locally validated `codex/<newer-model>` only when OpenClaw startup and `scripts/probe-codex-harness-turn.sh` both pass for that model. Do not auto-promote just because `/root/.codex/config.toml` names a newer model.

Do not use `codex-cli/*` as the primary model. The CLI backend remains useful as a fallback contract, but it is not the native Codex harness and has already failed on long silent turns, resume JSONL, and Telegram image/media prompts.

Do not persist `agents.defaults.embeddedHarness.fallback=none` on OpenClaw 2026.4.12. It can break gateway/channel startup before the Codex plugin registers. Use `fallback=none` only as an explicit probe override.

Validate:

```bash
scripts/validate-codex-harness-contract.sh
scripts/probe-codex-harness-turn.sh
```

## Codex CLI Fallback Contract

Fresh and resume calls are intentionally different:

```json
["exec","--json","--color","never","--dangerously-bypass-approvals-and-sandbox","--skip-git-repo-check"]
```

```json
["exec","resume","--json","--dangerously-bypass-approvals-and-sandbox","--skip-git-repo-check","{sessionId}"]
```

Do not copy fresh args into `resumeArgs`. Before changing this contract, check:

```bash
codex exec --help
codex exec resume --help
```

Because both vectors use `--json`, the required parser modes are also part of the contract:

```text
agents.defaults.cliBackends.codex-cli.output=jsonl
agents.defaults.cliBackends.codex-cli.resumeOutput=jsonl
```

Then update `scripts/bootstrap-openclaw.sh`, `scripts/validate-local-setup.sh`, `scripts/validate-codex-cli-contract.sh`, `scripts/validate-codex-harness-contract.sh`, and this playbook in the same commit.

## User-Visible Recovery Rule

If the user reports `Something went wrong`, `No response generated`, or silence after work:

- Do not ask for the whole context first.
- Check `journalctl -u openclaw-gateway.service`.
- Check `/tmp/openclaw/openclaw-YYYY-MM-DD.log`.
- Check `workspace/memory/YYYY-MM-DD.md`.
- Check relevant project dossier under `workspace/memory/projects/`.
- For a large project dossier, check both the header and the latest/current sections near the tail; do not rely on only the first `sed` page.
- Check whether the target project repo has completed work in `git status` and recent commits.
- Tell the user the precise layer that failed.

The correct answer must distinguish local work completion, model/runtime failure, and channel delivery failure.

## Context Exhaustion

If Telegram keeps returning generic failures while `openclaw-gateway` is healthy, run `openclaw status --json` and inspect the recent main session. `remainingTokens=0`, extreme `percentUsed`, or `status=failed` means the active chat session is no longer a safe working context.

Do not delete memory to fix this. Confirm the latest project state is in `workspace/memory/YYYY-MM-DD.md` and the project dossier, then start a new chat session with `/new`. Keep `agents.defaults.contextPruning.mode=cache-ttl`, `agents.defaults.contextPruning.ttl=5m`, `session.reset.mode=daily`, `session.reset.atHour=4`, and `session.resetByType.direct.idleMinutes=240` validated so future long-running DM sessions do not accumulate indefinitely.

## Telegram Durable Outbox

If Telegram shows `Recovered after an earlier Telegram delivery failure` followed only by generic `Something went wrong` text, treat it as stale transport recovery, not proof that the current model turn failed. Check `/tmp/openclaw/openclaw-YYYY-MM-DD.log` for `durable outbox queued`, `durable outbox delivered`, and the original `sendMessage failed` timestamp.

Durable outbox should be used for real final assistant replies that failed to deliver. It must not preserve generic processor-failure fallback text, because that stale error can be delivered later and look like the response to a new prompt. Validate the `telegram-durable-outbox-skip-generic-failures` runtime patch with `scripts/validate-local-setup.sh`.
