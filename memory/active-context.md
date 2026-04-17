# Active Context

## Current Environment

- OpenClaw is installed locally in `/home/OpenClaw/.openclaw`
- OpenClaw runtime home is isolated in `/home/OpenClaw/.openclaw-home`
- Default agent workspace is `/home/OpenClaw/workspace`
- Local memory vault is `/home/OpenClaw/memory`

## Current Defaults

- Prefer local launch via `/home/OpenClaw/bin/openclaw-local`
- Keep agent notes in Markdown
- Promote durable facts into `decisions.md` or `references/`
- Keep ad hoc captures in `inbox/`
- Keep the primary model on `codex-cli/gpt-5.4`
- Keep secrets only in ignored local paths, not tracked repo files

## Current Live State

- The local gateway is running on loopback and passes `gateway probe`
- Telegram bot connectivity is configured locally via `channels.telegram.tokenFile`
- Telegram channel probe is healthy
- Telegram owner access is now persisted in local runtime config via `allowFrom` plus `dmPolicy=allowlist`

## Next Steps

- Wait for a fresh Telegram DM after the allowlist restart, then confirm end-to-end chat handling
- Keep repo docs aligned with the public-safe operating model
