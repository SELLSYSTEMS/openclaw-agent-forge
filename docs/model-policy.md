# Model Policy

OpenClaw on this host class should use Codex CLI auth with the bundled Codex app-server harness as the default model/runtime path.

## Baseline

The supported baseline model is:

- `codex/gpt-5.6-sol`

The preferred reasoning floor is:

- `max`

Use the explicit `gpt-5.6-sol` slug rather than the `gpt-5.6` alias. OpenAI's model guidance identifies GPT-5.6 Sol as the routed model and advertises `max` for the hardest quality-first work.

## Runtime Split

Do not use `codex-cli/*` as the primary Telegram/OpenClaw runtime on this host class.

OpenClaw's own CLI backend docs describe CLI backends as fallback/safety-net runtime. That path has already caused repeated production issues here: no-output watchdog kills, raw JSONL delivery, Telegram `429` floods, and media turns failing with `No prompt provided via stdin`.

Use:

- primary embedded runtime: `codex/<model>` with `agents.defaults.embeddedHarness.runtime=codex`
- fallback CLI contract only: `codex-cli/<model>` with explicit no-sandbox args and `output=jsonl` / `resumeOutput=jsonl`

## Newer Models

A model newer than `gpt-5.6-sol` may be used only after local validation.

Accepted pattern:

- `codex/<validated-newer-model>`

Validation means more than `codex login status` or a shared `/root/.codex/config.toml` default. It must include:

- reboot-safe OpenClaw gateway startup with no fatal channel startup failure
- `scripts/validate-codex-harness-contract.sh`
- `scripts/probe-codex-harness-turn.sh`

On 2026-05-22, OpenClaw gateway startup logged `startup model warmup failed ... Unknown model` for `codex/*` before plugin discovery. Treat that as a known boot-order warning, not as a standalone reason to abandon the Codex harness. The hard failure to avoid is fatal channel startup or a failed Codex smoke/probe.

The known-good repo profile pins OpenClaw `2026.4.12`. That release predates native `max` support in its config schema and Codex bridge, so `scripts/apply-openclaw-runtime-patches.sh` must apply its version-guarded `gpt-5.6-sol-max-compat` patch. Unknown runtime shapes fail closed; do not blindly patch or upgrade them.

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

Official model reference: `https://developers.openai.com/api/docs/guides/latest-model`
