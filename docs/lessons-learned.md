# Lessons Learned

## Installation

- The official installer is the correct starting point for a local prefix install.
- A local prefix is better than a global install on a shared machine.
- The installed CLI was verified as `OpenClaw 2026.4.12 (1c0672b)` during bootstrap.
- The bootstrap should encode the preferred model path, not leave it implicit.

## Isolation

- OpenClaw config normally lives under `~/.openclaw/openclaw.json`.
- For this setup, `OPENCLAW_HOME=<REPO_ROOT>/.openclaw-home` is mandatory.
- Without isolated runtime home, sessions and config can mix with unrelated agent state.
- `gateway.mode=local` plus `gateway.bind=loopback` is the safe default on a shared machine.

## Memory

- Local Markdown files are the best default memory backend here.
- `ripgrep` is enough for the current scale.
- Obsidian is acceptable as a user interface over the same folder.
- A vector database should be added only after keyword retrieval becomes insufficient.
- A fresh OpenClaw install needs tracked seeded context before first user contact; otherwise it falls back to generic blank-slate bootstrap behavior.
- If OpenClaw says it cannot restore project context while project dossiers exist on disk, check the embedded Codex CLI sandbox args first. In one real failure, `codex-cli` started with bundled `--sandbox workspace-write`, every shell read failed with `bwrap: Failed to make / slave: Permission denied`, and the agent therefore could not read `memory/projects/interviewcoach.md` or daily memory.

## Model And Auth

- `codex/gpt-5.4` is the current minimum model floor for this repo, with Codex CLI auth and the bundled Codex app-server harness as the intended runtime path, not a forever pin.
- Shared Codex reasoning should stay on `xhigh`.
- If the shared Codex user default moves to a numerically newer GPT model than `gpt-5.4`, OpenClaw may follow it only after OpenClaw startup and `scripts/probe-codex-harness-turn.sh` validation as `codex/<model>`.
- This setup should prefer Codex CLI login reuse over `OPENAI_API_KEY`.
- Do not switch normal OpenClaw install/runtime behavior to direct API-key auth when Codex CLI reuse is available.
- On this host class, all webterminal tabs share the same Unix user, so Codex login is a shared user-level state rather than a per-tab concern.
- A successful `codex login status` plus a successful `codex exec ...` smoke test proves the auth path is usable.
- A healthy Codex login is not enough by itself. Embedded `codex-cli` turns can still die from OpenClaw's own no-output watchdog if the repo does not override it.
- Do not make `codex-cli/*` the primary Telegram/OpenClaw model path on this host class. OpenClaw documents CLI backends as fallback/safety-net runtime, and this host has already hit multiple independent failure modes from using that fallback layer as the primary runtime.
- The stable primary runtime pattern is `codex/<model>` with the bundled Codex app-server harness: `plugins.entries.codex.enabled=true`, `agents.defaults.embeddedHarness.runtime=codex`, boot-safe `agents.defaults.embeddedHarness.fallback=pi`, and explicit Codex smoke validation.
- Do not persist `agents.defaults.embeddedHarness.fallback=none` on OpenClaw 2026.4.12. During gateway startup, harness resolution can run before the Codex plugin has registered; persisted `fallback=none` can break Telegram/channel startup after reboot.
- On 2026-05-22, OpenClaw gateway warmup logged `Unknown model` for `codex/*` before Codex plugin discovery. Treat that as a known boot-order warning; do not confuse it with the fatal `fallback=none` channel-startup failure.
- If a Telegram media/image turn fails after successful media understanding with `No prompt provided via stdin`, treat it as a `codex-cli` prompt/image delivery failure. The correct durable fix is the Codex app-server harness, not another one-off CLI arg patch.

## Gateway Operations

- `openclaw-local health` and `openclaw-local gateway probe` are the fastest live checks.
- In this environment, running the gateway in tmux was more reliable than backgrounding it with `nohup`.
- OpenClaw's built-in Linux gateway install path expects systemd user services; on this host class, a repo-managed system service is the better reboot-persistent path.
- Some higher-scope gateway RPCs can still trigger a local `pairing required` repair request even when health and probe are healthy. Treat that as a gateway authorization layer issue, not a model/auth failure.
- Telegram native exec approvals auto-enable in `auto` mode when approvers can be inferred from `allowFrom` or `defaultTo`. On this host class, the stable default is to set `channels.telegram.execApprovals.enabled=false` unless native approvals are explicitly required.
- A read-only local device token such as `gateway:health` is insufficient for Telegram native approvals and creates repeating `pairing required` connect loops.
- Telegram channel probe can be healthy before any inbound DM arrives. Check `lastInboundAt` or send a fresh message after startup.
- Telegram can initially reply with `access not configured` while in pairing mode. After the first owner DM, approve pairing, then move to local `allowFrom` plus `dmPolicy=allowlist` for a more durable owner-only setup.
- Outbound Telegram success is not enough to claim audio readiness. For Telegram voice-note use, require validated local STT and state explicitly whether real inbound voice-note transcription has already been proven.
- A healthy gateway and healthy Telegram transport do not prove a long embedded Codex turn will survive. The main failure can still be an internal `cli watchdog timeout` while the service stays up.
- Raw Codex JSONL in Telegram is a parser/output-mode contract failure, not proof that memory or model reasoning failed. If `codex-cli.args` or `resumeArgs` include `--json`, then `agents.defaults.cliBackends.codex-cli.output` and `resumeOutput` must both be `jsonl`. A missing `resumeOutput=jsonl` can make OpenClaw send the whole Codex event stream, including tool output/code, as Telegram text and trigger `429 Too Many Requests`.
- If raw JSONL flood created queued Telegram messages, stop the gateway first, move stale durable-outbox files to a local quarantine directory, fix the output modes, then restart. Do not delete memory or session state to solve a delivery-layer issue.
- Telegram `MEDIA:` delivery can fail after the agent already produced a useful final answer. A 77.8 MB Android APK triggered `sendDocument` `413: Request Entity Too Large`, and Telegram showed a generic failure. Check artifact size before `MEDIA:` and avoid direct Telegram attachment for oversized APKs.
- Artifact delivery needs a destination-specific preflight across all systems, not only Telegram. Check live limits, file size, file type, auth/exposure, fallback path, and final URL/result before claiming delivery succeeded.
- OpenClaw 2026.4.12 can drop a completed Codex app-server answer if the app-server emits a normal assistant message and then a generic prompt-level `codex app-server error`. The symptom is Telegram showing `Something went wrong` while the session transcript contains a useful assistant message with `stopReason=error`. Keep `scripts/apply-openclaw-runtime-patches.sh` applied and validated so post-answer app-server errors preserve the generated reply instead of replacing it with a generic Telegram failure.
- The first Codex app-server recovery guard was too narrow because a valid reply can be present on `sessionLastAssistant` while the outer runner still treats the turn as a prompt-stage failure. Require the `codex-app-server-recovery-v2` marker too; it bypasses prompt-stage failover when visible assistant text already exists.
- A long Telegram turn can be lost if a heavy child process spawned by OpenClaw, such as a JVM/Gradle/Android tool process, is OOM-killed inside the gateway systemd cgroup. On 2026-05-26 04:00 UTC, systemd reported `openclaw-gateway.service: A process of this unit has been killed by the OOM killer`, `Failed with result 'oom-kill'`, and `8.7G memory peak`; with `OOMPolicy=stop`, systemd stopped and restarted the whole gateway. Keep the repo-managed unit on `OOMPolicy=continue` and validate it so child OOM does not kill the gateway itself.
- A stale generic Telegram failure can be self-inflicted by durable outbox. On 2026-05-27, Telegram `sendMessage` failed transiently around 17:23 UTC, OpenClaw queued the generic processor-failure text, then delivered it after a later user request around 18:06 UTC with the `Recovered after an earlier Telegram delivery failure` prefix. Durable recovery should keep real final assistant replies, but skip/drop non-actionable generic failure text using the `telegram-durable-outbox-skip-generic-failures` patch.
- Reusing the same direct Telegram session for days can exhaust context even when memory files are healthy. On 2026-05-27, `openclaw status` showed the main session at `remainingTokens=0`, `percentUsed=999`, and `status=failed` while current memory/project dossier files were present. Keep explicit daily/direct idle reset policy and context pruning enabled; use `/new` after long project runs once the latest state is written to memory.

## Tooling Mistakes To Avoid

- Do not commit the installed runtime tree.
- Do not assume helper scripts work without a smoke-test.
- Do not store durable decisions only in chat history; promote them into tracked files.
- Do not let the first Telegram DM become the place where OpenClaw learns the host basics; seed those in tracked workspace files before channels are connected.
- Do not make a GitHub repo depend on local state that cannot be rebuilt from scripts.
- Do not write multiple `openclaw config set` updates in parallel against the same config file; one write can clobber the other.
- Do not place bot tokens or other secrets into tracked docs, scripts, or memory files when the GitHub repo is public.
- Do not place owner-specific Telegram IDs into tracked docs when the GitHub repo is public.
- Do not default to OpenClaw's built-in `coding-agent` / side `codex exec` worker path for long Telegram coding tasks. A silent PTY worker can be terminated after 180 seconds of no output and then surface to the human only as a generic bot failure.
- Do not use `codex-cli/*` as the primary runtime just because it can reuse Codex login. Keep it as a fallback contract and validate primary `codex/*` with `scripts/validate-codex-harness-contract.sh` plus `scripts/probe-codex-harness-turn.sh` after runtime/model changes.
- Do not leave the embedded `codex-cli` backend on stock no-output watchdog settings for this host class. Set a day-scale agent timeout, disable `agents.defaults.llm.idleTimeoutSeconds`, use `contextInjection=continuation-skip`, and override the `codex-cli` fresh/resume watchdogs to a day-scale value.
- Do not leave the embedded `codex-cli` backend on the bundled `--sandbox workspace-write` args for this host class. Override both `args` and `resumeArgs` to use `--dangerously-bypass-approvals-and-sandbox`, and make validation fail if the bundled sandbox default returns.
- Do not copy fresh `codex exec` args directly into `resumeArgs`. Current `codex exec resume` does not accept `--color`; the working resume vector is `["exec","resume","--json","--dangerously-bypass-approvals-and-sandbox","--skip-git-repo-check","{sessionId}"]`. A bad resume vector fails before model start and Telegram only shows a generic failure.
- Do not configure `codex-cli --json` without explicit `output=jsonl` and `resumeOutput=jsonl`. Otherwise OpenClaw may ship raw JSONL/tool output to the user instead of extracting the final `agent_message`.
- Add a script-level regression gate for any failure that could recur across future agents. For Codex CLI fresh/resume drift, the permanent gate is `scripts/validate-codex-cli-contract.sh`, and it must be run after installs, repairs, and CLI upgrades.
- If you intentionally spawn a side worker, monitor it as background work and keep the parent chat updated. Do not let the parent session sit idle while a child CLI runs off-screen.
- For fresh installs on this host class, no-sandbox / danger-full-access should be the default operator mode. If the shell sandbox throws `bwrap: Failed to make / slave: Permission denied`, treat that as proof the wrong runtime was used and switch immediately.
- Do not introduce cron as default automation during install or repair. Use local Node-RED for durable automation unless the user explicitly asked for cron.
