# Model Migration And Quota Recovery

The validated baseline is `codex/gpt-6-astra` with `max` reasoning, using the existing Codex CLI login. Do not change the product's other providers, credentials, global Codex config, or unrelated services during this operation.

## Diagnose Before Changing Anything

1. Check systemd, `bin/openclaw-local channels status --probe --json`, recent gateway logs, and `node scripts/inspect-last-turn.mjs`. A process being `active` or a bot probe succeeding does not prove a task is working.
2. Resolve the main session from `.openclaw-home/.openclaw/agents/main/sessions/sessions.json`. Inspect its transcript and `.codex-app-server.json` binding. Find the corresponding native rollout in the gateway user's actual `CODEX_HOME`, normally `$HOME/.codex/sessions`.
3. Correlate `task_started`/`task_complete`, recent transcript growth, gateway-owned processes and child work. `tasks.active=0` alone does not count every embedded Codex turn. Do not restart active work; wait for a safe boundary.
4. A provider usage-limit error is not a gateway crash. Record the provider's retry time privately. Local timeout changes and restarts do not restore provider quota. Do not automatically switch accounts, providers, or billed routes. An operator-approved candidate must pass a real probe using the existing authorized login.

The transcript inspection command emits only status/timestamps and an error class, never chat text. It is not a liveness assertion: `awaiting_or_interrupted` requires process and native-event checks. It does not schedule retries or restart anything.

## Validate The Candidate

Confirm the exact model id and advertised effort using official documentation and the installed Codex app-server model catalog. For Astra the id is `gpt-6-astra`, not an inferred `gpt-6` alias; use exactly the requested `max` effort even if the account advertises other efforts.

Keep OpenClaw `2026.4.12` pinned for this profile. Apply `scripts/apply-openclaw-runtime-patches.sh` before config changes. Preserve existing recovery/output/sandbox fixes. The historical `gpt-5.6-sol-max-compat` marker remains necessary for schema, normalization, and bridge support. The additional `gpt-6-astra-provider-compat` patch corrects Astra's offline reasoning metadata.

```bash
node scripts/validate-codex-model-compat.mjs
OPENCLAW_SMOKE_MODEL=codex/gpt-6-astra scripts/probe-codex-harness-turn.sh
```

The explicit candidate probe updates only its temporary config's primary model and allowlist. This avoids the old `Model override ... is not allowed` preflight failure without changing production. Never run smoke messages against the live Telegram session or resume the user's native thread for a test. A probe consumes a small amount of the approved Codex allowance; do not run it repeatedly after a quota rejection.

## Preserve Continuity And Switch

1. Confirm quiescence again immediately before stopping. Save a current private checkpoint in `workspace/memory` and the project's dossier, including incomplete work and approval boundaries. Do not put private project history in public Git.
2. Run `scripts/backup-openclaw-continuity-state.sh`. It backs up config, the full session store, transcript, binding sidecar, native Codex rollout, and workspace/repo memory archives with checksums under an ignored mode-0700 directory. If native history cannot be located, correct `CODEX_HOME`; do not claim a complete backup.
3. Stop only `openclaw-gateway.service`, then use `bin/openclaw-local models set codex/gpt-6-astra`. Keep `thinkingDefault=max` and the existing session's `thinkingLevel=max`. The model command also adds the target to the allowlist. Apply config writes sequentially.
4. Keep the same session id, transcript path, thread id and sidecar. Remove or replace an old per-session model override only if inspection finds one. Do not rewrite historical last-used model metadata to fake proof of a new turn.
5. Check session idle freshness. A multi-day quota stop may have already expired the 240-minute direct-chat idle window. For an explicitly requested same-session continuation, refresh only that entry's `updatedAt` while the gateway is stopped and record the old/new values in private migration notes. This is an operator continuity touch, not evidence of user activity. Do not change all sessions or permanently disable reset policy. Beyond the next idle window, the updated dossier remains the recovery source of truth.
6. Validate config, start the service, wait for plugin/channel initialization, and probe channels again. The first probe during cold startup can time out; do not mistake config-only fallback output for a successful live probe.
7. Verify unchanged transcript/native-rollout/sidecar hashes and the same session id. Compare config and session-store diffs against the backup. Keep rollback material private; restore the prior model/config only if the migration gates fail and no new user turn has begun.

## Verify And Publish

```bash
scripts/validate-codex-harness-contract.sh
scripts/validate-codex-cli-contract.sh
scripts/validate-local-setup.sh
scripts/probe-codex-harness-turn.sh
bin/openclaw-local channels status --probe --json
```

The normal post-switch probe leaves the live allowlist unchanged. Its default `agent` mode validates projected completion in an isolated workspace/home with no channels, using a private temporary copy of the existing file-backed Codex login. Probe history now lives in that temporary `CODEX_HOME`, not in the real user's thread. Inspect its native `turn_context` before cleanup when auditing the actual model and `effort=max`; do not confuse optional model-only `infer` mode with the full harness check. Check the gateway's startup model, enabled systemd unit, `OOMPolicy=continue`, and no fatal channel startup failure. No server reboot is required for this service-restart test.

OpenClaw 2026.4.12 can log a pre-plugin `Unknown model` warmup warning. An optional ACP side-worker probe can also fail independently of the primary `codex` app-server harness. Record such warnings, but do not conflate them with successful primary inference or ignore a fatal Telegram startup failure.

Update bootstrap defaults, validation gates, model policy, seeded workspace memory, installer prompt, and the dated decision together. Preserve historical model decisions and patch identifiers. Run regression tests and review the public diff for secrets before pushing over the established HTTPS remote. Do not commit `.codex/`, `.openclaw-home/`, transcripts, backup archives, or private recovery checkpoints.

Official references: [GPT-6 Astra model](https://developers.openai.com/api/docs/models/gpt-6-astra), [Codex usage limits](https://learn.chatgpt.com/docs/pricing#what-are-the-usage-limits-for-my-plan).
