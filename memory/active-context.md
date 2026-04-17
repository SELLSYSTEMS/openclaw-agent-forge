# Active Context

## Current Environment

- OpenClaw is installed locally in `/home/OpenClaw/.openclaw`
- OpenClaw runtime home is isolated in `/home/OpenClaw/.openclaw-home`
- Default agent workspace is `/home/OpenClaw/workspace`
- Local memory vault is `/home/OpenClaw/memory`
- Shared Codex CLI host state exists under `/root/.codex`
- Shared Node-RED host state exists under `/root/.node-red`
- Known current agent roots currently include `/home/admin`, `/home/langchain`, `/home/udacity`, and `/home/OpenClaw`
- Webterminal implementation exists under `/opt/claude-vnc-terminal`
- Webterminal tab state is readable from `/opt/claude-vnc-terminal/data/terminal-state.json`

## Current Defaults

- Prefer local launch via `/home/OpenClaw/bin/openclaw-local`
- Keep agent notes in Markdown
- Promote durable facts into `decisions.md` or `references/`
- Keep ad hoc captures in `inbox/`
- Keep the primary model on `codex-cli/gpt-5.4`
- Keep secrets only in ignored local paths, not tracked repo files
- Treat OpenClaw as the main orchestrator for this repo
- Prefer Node-RED for durable automations and cross-system flows when possible
- Prefer local repo config over mutating the global Codex CLI config in `/root/.codex`
- Treat webterminal access as a normal discovery surface on this host class, but keep exact instance URLs in local-only files
- Use the server-side terminal-state file, when present, as the fastest way to detect live webterminal tabs and their working directories

## Current Live State

- The local gateway is running on loopback and passes `gateway probe`
- Telegram bot connectivity is configured locally via `channels.telegram.tokenFile`
- Telegram channel probe is healthy
- Telegram owner access is now persisted in local runtime config via `allowFrom` plus `dmPolicy=allowlist`
- Telegram DM replies are now working end to end
- Shared host context is now documented in `docs/shared-host-context.md`
- OpenClaw TUI is the first recommended operator surface; Node-RED remains the preferred automation fabric

## Next Steps

- Use the new shared-host docs and `scripts/agent-landscape.sh` as the first discovery pass for future agents
- Evaluate whether a deeper custom dashboard is still needed after trying `openclaw-local tui`
- Keep repo docs aligned with the public-safe operating model
