# Model Policy

OpenClaw on this host class should use Codex CLI as the default model/auth path.

## Baseline

The supported baseline model is:

- `codex-cli/gpt-5.4`

The preferred reasoning floor is:

- `xhigh`

## Unsuitable Model

Do not use:

- `gpt-5.5`

Treat `gpt-5.5` as unsuitable for this operator pattern. If an existing OpenClaw config or shared Codex config resolves to `gpt-5.5`, the installer must override it to `codex-cli/gpt-5.4` before continuing.

## Newer Models

A model newer than `5.5` may be used only after local validation.

Accepted pattern:

- `codex-cli/<validated-newer-model>`

Do not switch to a direct OpenAI API model path unless the user explicitly instructs it.

## Auth Ownership

Authentication belongs to Codex CLI.

Required checks:

- `which codex || true`
- `codex login status`

Do not make `OPENAI_API_KEY` the default auth path for this repo.
