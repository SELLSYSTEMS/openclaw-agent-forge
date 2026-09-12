# Model Policy

OpenClaw on this host class should use Codex CLI auth with the bundled Codex app-server harness as the default model/runtime path.

## Baseline

The supported baseline model is:

- `codex/gpt-6-astra`

The preferred reasoning floor is:

- `max`

Use the exact `gpt-6-astra` slug. OpenAI's [model reference](https://developers.openai.com/api/docs/models/gpt-6-astra) advertises `max`; the installed Codex account must also advertise it. Do not infer a model id from a marketing name or select a higher effort automatically.

## Runtime Split

Do not use `codex-cli/*` as the primary Telegram/OpenClaw runtime on this host class.

OpenClaw's own CLI backend docs describe CLI backends as fallback/safety-net runtime. That path has already caused repeated production issues here: no-output watchdog kills, raw JSONL delivery, Telegram `429` floods, and media turns failing with `No prompt provided via stdin`.

Use:

- primary embedded runtime: `codex/<model>` with `agents.defaults.embeddedHarness.runtime=codex`
- fallback CLI contract only: `codex-cli/<model>` with explicit no-sandbox args and `output=jsonl` / `resumeOutput=jsonl`

## Newer Models

A model newer than `gpt-6-astra` may be used only after local validation and operator approval.

Accepted pattern:

- `codex/<validated-newer-model>`

Validation means more than `codex login status` or a shared `/root/.codex/config.toml` default. It must include:

- reboot-safe OpenClaw gateway startup with no fatal channel startup failure
- `scripts/validate-codex-harness-contract.sh`
- `scripts/probe-codex-harness-turn.sh`

On 2026-05-22, OpenClaw gateway startup logged `startup model warmup failed ... Unknown model` for `codex/*` before plugin discovery. Treat that as a known boot-order warning, not as a standalone reason to abandon the Codex harness. The hard failure to avoid is fatal channel startup or a failed Codex smoke/probe.

The known-good repo profile pins OpenClaw `2026.4.12`. That release predates native `max` support in its config schema and Codex bridge, so `scripts/apply-openclaw-runtime-patches.sh` must apply its version-guarded `gpt-5.6-sol-max-compat` patch. Unknown runtime shapes fail closed; do not blindly patch or upgrade them.

The historical max-patch name is retained for idempotence; it also forwards Astra's `max` effort. Astra additionally requires `gpt-6-astra-provider-compat` on this runtime: otherwise offline dynamic resolution reports `reasoning=false`. `node scripts/validate-codex-model-compat.mjs` validates the provider behavior without a network call.

Follow [model-migration-runbook.md](model-migration-runbook.md) before changing a live model. Do not restart active work, reset a session, or treat migration as a workaround for provider usage limits.

Do not switch to a direct OpenAI API model path unless the user explicitly instructs it.

## Auth Ownership

Authentication belongs to Codex CLI.

Required checks:

- `which codex || true`
- `codex login status`
- `codex app-server --help`
- `scripts/validate-codex-harness-contract.sh`
- `scripts/probe-codex-harness-turn.sh`

Do not make `OPENAI_API_KEY` the default auth path for this repo.

Official model reference: [GPT-6 Astra](https://developers.openai.com/api/docs/models/gpt-6-astra).
