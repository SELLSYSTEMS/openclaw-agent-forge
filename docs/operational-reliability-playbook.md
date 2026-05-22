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
- Oversized artifacts: Telegram direct upload can fail for APKs. Run delivery preflight and provide a safe link/path instead of forcing direct attachment.
- `pairing required` on admin-style RPCs: separate gateway authorization issue. Do not confuse it with Telegram health, model auth, or memory loss.
- Parallel OpenClaw config writes: can clobber each other. Apply config writes sequentially.
- Context recovery failure while memory exists: usually runtime access/config failure, not missing knowledge.

## Required Gates

Run these after install, repair, or Codex/OpenClaw upgrade:

```bash
scripts/validate-codex-cli-contract.sh
scripts/validate-local-setup.sh
```

For service state:

```bash
systemctl status openclaw-gateway.service --no-pager
bin/openclaw-local health
```

For host topology:

```bash
scripts/agent-landscape.sh
```

## Codex CLI Backend Contract

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

Then update `scripts/bootstrap-openclaw.sh`, `scripts/validate-local-setup.sh`, `scripts/validate-codex-cli-contract.sh`, and this playbook in the same commit.

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
