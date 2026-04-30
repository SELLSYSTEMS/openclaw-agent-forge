# Decisions

## 2026-04-13

### Use an isolated local OpenClaw runtime

- Decision: set `OPENCLAW_HOME=<REPO_ROOT>/.openclaw-home`
- Why: prevents session, config, and runtime state from colliding with other agents or global CLI state

### Use file-based memory as the primary memory system

- Decision: store memory in local Markdown files under `<REPO_ROOT>/memory`
- Why: transparent, local, easy for agents to read, easy to diff, and operationally simpler than a vector database

### Keep Obsidian optional

- Decision: if a GUI is needed later, use Obsidian on the same `memory/` folder
- Why: this keeps one source of truth while adding a human-friendly editor

## 2026-04-17

### Use Codex CLI as the default OpenClaw model path

- Decision: keep the primary model floor on `gpt-5.4`, treat Codex CLI as the intended backend path, inherit `xhigh` reasoning from the shared Codex user config, and move to a newer shared GPT model once it is numerically newer than 5.5 and validated locally
- Why: this reuses the installed Codex CLI login, avoids making `OPENAI_API_KEY` the default auth path, and keeps OpenClaw aligned with the newest stable shared-user Codex model instead of freezing forever on 5.5

### Keep repo knowledge public-safe and secrets local-only

- Decision: store channel tokens and similar secrets only under ignored local paths such as `<REPO_ROOT>/.openclaw-home/secrets/`
- Why: `SELLSYSTEMS/openclaw-agent-forge` is public and should preserve operational knowledge without leaking credentials

### Keep Telegram setup reproducible without tracking credentials

- Decision: document the secret file path pattern and channel setup flow, but never the token itself
- Why: future agents need the procedure and the exact local path model, not the credential

### Persist Telegram owner access only in local runtime config

- Decision: after the first successful owner DM, keep the owner's Telegram user ID only in local OpenClaw config and switch DM access to allowlist mode
- Why: this avoids repeated pairing prompts while keeping owner-specific identifiers out of the public repo

### Treat OpenClaw as the orchestrator and Node-RED as the preferred automation fabric

- Decision: use OpenClaw as the coordination layer for this repo, and prefer Node-RED when building durable automations, bridges, or human-readable schemes
- Why: OpenClaw owns the agent workflows here, while Node-RED is already present on the host and is a better fit for repeatable automation and visual flow management
- Constraint: when Node-RED is shared with user-owned flows, keep OpenClaw work in a dedicated new OpenClaw-specific tab/project scope so it does not mix with or break unrelated flows

### Keep CLI auth/execution mandatory and cron opt-in only

- Decision: for normal installs on this host class, keep Codex CLI as the only default model/auth execution path, do not switch to direct `OPENAI_API_KEY` auth, and do not create cron-based automation unless the user explicitly asks for cron
- Why: the shared Codex CLI login is already the intended repo execution path, while local Node-RED is the correct durable automation fabric and avoids hidden scheduler drift during install or repair

### Treat Telegram audio readiness as an explicit install gate

- Decision: for Telegram-enabled installs, do not claim completion from text transport alone; require validated local STT and explicitly state whether real inbound voice-note transcription has been proven yet
- Why: Telegram text transport can succeed while audio handling is still broken or unverified, which creates false 'install complete' claims

### Treat `/root/.codex` as shared host context, not repo-owned state

- Decision: let future agents read shared Codex CLI context from `/root/.codex`, but avoid mutating global config unless the user explicitly asks
- Why: several Codex agents already run on the host, and repo-local changes should not accidentally break the global setup

### Treat Node-RED as shared-by-default server infrastructure

- Decision: document Node-RED as installed and available to all agents on this server class, even if its flows are initially empty
- Why: future agents should assume it exists as a shared automation resource instead of rediscovering or reinstalling it

### Detect webterminal tabs from server-side state, not only from browser assumptions

- Decision: treat `/opt/claude-vnc-terminal/data/terminal-state.json` as the primary discovery file for current webterminal tabs when it exists
- Why: this gives future agents and OpenClaw a direct server-side view of tab names, working directories, and providers without relying on the browser UI

### Seed important OpenClaw memory directly in the workspace

- Decision: keep a tracked, public-safe `workspace/MEMORY.md` with the core operating facts for this server class
- Why: future installs and future agents should start with the right context immediately, without needing to reconstruct it from chat history or re-read the whole repo first

### Seed host knowledge before first external conversation

- Decision: keep the tracked workspace startup files as the source of first-run host knowledge and require them before the first user chat or Telegram connection
- Why: OpenClaw should begin with the machine context already loaded and ask only for missing personalization instead of learning the server basics from the first DM

### Document the shared Codex CLI TUI explicitly

- Decision: keep a dedicated `docs/codex-cli-tui.md` runbook for the OpenAI Codex CLI TUI used by the other terminal agents
- Why: OpenClaw should understand that the neighboring agents are running the Codex TUI, how it is enabled, and which host-level defaults already apply

### Treat Codex TUI enablement as a CLI install and login concern

- Decision: document that enabling the Codex TUI for all server-side terminal agents means keeping `codex` installed on `PATH` plus a valid `~/.codex` login for the session user, not installing a second TUI package
- Why: this prevents future agents from wasting time looking for a non-existent separate TUI component and keeps the shared-host setup simple

### Treat Codex login as shared user state on this host class

- Decision: document that the browser-terminal tabs on this host class share the same Unix user and therefore the same `~/.codex` login state
- Why: future agents should not repeat pointless per-tab login instructions when the login already exists for the shared session user
