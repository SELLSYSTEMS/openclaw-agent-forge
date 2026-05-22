# Model Policy

OpenClaw on this host class should use Codex CLI auth with the bundled Codex app-server harness as the default model/runtime path.

## Baseline

The supported baseline model is:

- `codex/gpt-5.4`

The preferred reasoning floor is:

- `xhigh`

## Runtime Split

Do not use `codex-cli/*` as the primary Telegram/OpenClaw runtime on this host class.

OpenClaw's own CLI backend docs describe CLI backends as fallback/safety-net runtime. That path has already caused repeated production issues here: no-output watchdog kills, raw JSONL delivery, Telegram `429` floods, and media turns failing with `No prompt provided via stdin`.

Use:

- primary embedded runtime: `codex/<model>` with `agents.defaults.embeddedHarness.runtime=codex`
- fallback CLI contract only: `codex-cli/<model>` with explicit no-sandbox args and `output=jsonl` / `resumeOutput=jsonl`

## Newer Models

A model newer than `gpt-5.4` may be used only after local validation.

Accepted pattern:

- `codex/<validated-newer-model>`

Do not switch to a direct OpenAI API model path unless the user explicitly instructs it.

## Auth Ownership

Authentication belongs to Codex CLI.

Required checks:

- `which codex || true`
- `codex login status`
- `codex app-server --help`
- `scripts/validate-codex-harness-contract.sh`

Do not make `OPENAI_API_KEY` the default auth path for this repo.
