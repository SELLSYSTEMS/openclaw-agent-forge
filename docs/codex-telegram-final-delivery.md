# Codex Completion Is Not Telegram Delivery

## Incident And Root Cause

On 2026-09-13 a long task had completed in native Codex, but its final report never reached Telegram. Gateway uptime, memory and the bot probe were healthy; the durable outbox was empty. Restarting the project or deleting conversation memory would not fix this.

Three defects in OpenClaw `2026.4.12` interacted:

1. Its event projector read `params.message` instead of app-server v2 `params.error.message`, treated `willRetry=true` as fatal, and never cleared that notification error when `turn/completed` reported `status=completed`. Native Codex recovered from a temporary model-access/stream error, but OpenClaw mirrored a generic failure into its transcript.
2. Reply preparation suppressed every final payload after a same-destination `message` tool send. A progress update hid a different final report before Telegram delivery or its outbox could run. The upstream substring deduper could also discard a longer final that quoted progress.
3. Earlier text-based recovery guards were too broad: partial text, or a previous turn's answer, was not proof that the current turn succeeded. Such a guard could hide a genuine failure.

This protocol/status and reply-selection incident is distinct from memory loss, actual account quotas, Telegram rate limits, artifact limits and child-process OOM incidents.

## Reproducible Repair

`scripts/patch-codex-delivery.mjs`, invoked by `scripts/apply-openclaw-runtime-patches.sh`, installs three shape-checked patches:

- `codex-app-server-terminal-status-v3`: respect nested, scoped errors and `willRetry`; use authoritative terminal status; retain failures, interrupts and timeouts. Preserve a typed `codexTurnStatus` on the mirrored assistant record.
- `codex-terminal-recovery-guard`: historical recovery requires a completed, non-error assistant from the current attempt, not just any text. A prior answer cannot recover a new failed turn.
- `codex-telegram-distinct-final`: only for `codex` + Telegram, keep distinct automatic final replies after progress sends. Deduplicate exact whitespace-normalized text and previously sent media, preserving new media even when its caption was sent. Keep silence and already-streamed controls. Other providers and channels retain their original policy.

All three target shapes and syntax are checked before these changes are written. Reapplication is idempotent; `--check` validates complete replacements, not just markers. The legacy patch installer refuses unvalidated OpenClaw versions before any writes. Never blindly apply these replacements to a newer build.

Clean-package CI also exposed an older prerequisite missing from Git: the Telegram text outbox itself was a local customization, not part of the stock npm package. `scripts/ensure-telegram-outbox-base.mjs` now reproduces the existing customization from a tracked diff with exact before/after hashes, version, hunk and syntax checks. It leaves an already managed live bot file untouched and rejects unknown local changes. See [patch provenance and license](../patches/README.md).

This legacy outbox is bounded text-recovery support, not an exactly-once delivery guarantee or coverage of every exception path. It cannot recover a final suppressed before transport, and its in-process retry timers are not a persistent scheduler. Checkpoints and stage-specific receipts remain required.

## Mandatory Tests

```bash
scripts/apply-openclaw-runtime-patches.sh
node scripts/patch-codex-delivery.mjs --check
node --test scripts/codex-delivery.test.mjs
node scripts/ensure-telegram-outbox-base.mjs --check
node --test scripts/telegram-outbox.test.mjs
scripts/validate-codex-harness-contract.sh
scripts/validate-codex-cli-contract.sh
scripts/validate-local-setup.sh
scripts/probe-codex-harness-turn.sh
```

The regression suite extracts the installed event projector and reply builder, imports real directive/deduplication functions and the Telegram formatter/delivery module, and substitutes the external Telegram API boundary. It makes no model calls or Telegram sends. Cases cover retries, fatal errors, stale/foreign events, timeout/interruption, prior-turn recovery, distinct/identical finals, quoted progress, media, silence, streaming, recipient/account boundaries and rejected sends.

CI installs the pinned runtime without credentials, applies the patches, runs tests and repeats application. A mocked transport is not a live Telegram receipt. The default harness smoke now runs an isolated embedded agent, checks its projected transcript for `codexTurnStatus=completed` and `stopReason=stop`, and disables channels. `OPENCLAW_CODEX_SMOKE_MODE=infer` remains a narrower optional model-only probe, not a substitute for this regression gate.

The outbox suite verifies the official stock-file hash, exact reconstruction, no-write idempotence, rejection of modified files, generic-failure exclusion, durable text retention on failed/unacknowledged sends, acknowledged removal, bounded backoff and account/chat/due-time isolation. It uses temporary storage and mocked network/timers, never the live queue.

The smoke copies the existing file-backed Codex login/config into a private, temporary `CODEX_HOME` beneath the ignored runtime home; it does not create a new login or use an API key. The directory and copies are removed afterward. This also prevents native workspace-trust writes from polluting the shared Codex config. A keyring-only/custom auth setup needs an explicitly validated isolation strategy, not an automatic auth change.

## Runtime Evidence

Check the stages separately:

1. Work: native Codex terminal event, final report and project checkpoint. Resolve the current transcript and native thread from the session store/sidecar rather than guessing filenames.
2. Projection: `[codex-turn-status]` reports terminal status and retriable-error count without response bodies. Do not rewrite a historical transcript error just to make a status command green.
3. Preparation: `[codex-telegram-final] stage=prepared` reports payload counts. Zero output needs investigation of silence, deduplication or streaming. Preparation is not a send receipt.
4. Delivery: match the later `telegram sendMessage ok ... message=...`, preview finalization or durable-outbox receipt to the correct turn. A healthy probe, old outbound timestamp or empty outbox alone proves none of this.

Use existing gateway/native logs. Do not add cron restart loops or emit raw JSONL/tool output into chat. Persist project checkpoints before final delivery; recover completed work instead of replaying side effects.

Before reload, confirm no active native turn or queued work, back up continuity, and stop only the gateway. Preserve session, transcript, native history and binding. Follow [model-migration-runbook.md](model-migration-runbook.md) for a privately audited one-session idle-freshness touch when preserving continuation. Never append test prompts to the real Telegram transcript.

## Official References

- [Codex app-server errors](https://learn.chatgpt.com/docs/app-server#errors): distinguish error notifications from terminal failure. Confirm the installed protocol with `codex app-server generate-json-schema --out <PRIVATE_DIR>`; v2 `ErrorNotification` includes `error`, `willRetry`, `threadId` and `turnId`.
- [OpenClaw runtime ownership](https://docs.openclaw.ai/plugins/codex-harness-runtime): native Codex execution/history and OpenClaw delivery/transcript mirroring are separate responsibilities.
- [Current OpenClaw replies](https://docs.openclaw.ai/plugins/codex-harness-runtime/replies): architectural guidance for newer finalization behavior, not evidence this pinned release already implements it. Completed actions must not be replayed to regenerate a report.
