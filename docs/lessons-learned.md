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

## Model And Auth

- `gpt-5.4` is the current minimum model floor for this repo, with Codex CLI as the intended backend path, not a forever pin.
- Shared Codex reasoning should stay on `xhigh`.
- If the shared Codex user default moves to a numerically newer GPT model than 5.5, OpenClaw should follow it after validation.
- This setup should prefer Codex CLI login reuse over `OPENAI_API_KEY`.
- Do not switch normal OpenClaw install/runtime behavior to direct API-key auth when Codex CLI reuse is available.
- On this host class, all webterminal tabs share the same Unix user, so Codex login is a shared user-level state rather than a per-tab concern.
- A successful `codex login status` plus a successful `codex exec ...` smoke test proves the auth path is usable.
- A healthy Codex login is not enough by itself. Embedded `codex-cli` turns can still die from OpenClaw's own no-output watchdog if the repo does not override it.

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
- Do not leave the embedded `codex-cli` backend on stock no-output watchdog settings for this host class. Set a day-scale agent timeout, disable `agents.defaults.llm.idleTimeoutSeconds`, use `contextInjection=continuation-skip`, and override the `codex-cli` fresh/resume watchdogs to a day-scale value.
- If you intentionally spawn a side worker, monitor it as background work and keep the parent chat updated. Do not let the parent session sit idle while a child CLI runs off-screen.
- For fresh installs on this host class, no-sandbox / danger-full-access should be the default operator mode. If the shell sandbox throws `bwrap: Failed to make / slave: Permission denied`, treat that as proof the wrong runtime was used and switch immediately.
- Do not introduce cron as default automation during install or repair. Use local Node-RED for durable automation unless the user explicitly asked for cron.
