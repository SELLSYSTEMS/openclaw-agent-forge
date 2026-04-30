# Prompt Patterns

These prompts are starter patterns for future agents working with this repository and host.

They are intentionally public-safe:

- no secrets
- no owner-specific IDs
- no pasted credentials

## 1. Shared Host Discovery

Use this when a new agent wakes up on the machine and needs orientation.

```text
Read README.md, docs/install-runbook.md, docs/shared-host-context.md, docs/orchestrator-roadmap.md, workspace/AGENTS.md, and workspace/TOOLS.md. Then run scripts/agent-landscape.sh. Summarize:
1. what OpenClaw owns locally,
2. which shared host services already exist,
3. which configs are repo-local versus global,
4. what must stay out of Git because the repo is public,
5. whether `/opt/claude-vnc-terminal/data/terminal-state.json` reveals additional live tabs or roots.
Do not modify global config unless the user explicitly asks.
```

## 2. Public-Safe Documentation Pass

Use this after a successful setup or debugging session.

```text
Take the working result and promote only the safe operational knowledge into docs/ and memory/. Keep secrets, passwords, owner-specific IDs, and private transcripts out of tracked files. If the operating model changed, update AGENTS.md, docs/shared-host-context.md, docs/orchestrator-roadmap.md, and the relevant memory files in the same change.
```

## 3. Automation Choice

Use this when deciding where a new integration or workflow should live.

```text
Decide whether the task belongs in OpenClaw, Node-RED, or a small local script. Prefer OpenClaw for agent coordination, Node-RED for durable automations and visual flows, and repo-local scripts for small explicit utilities. If you use shared Node-RED, create a dedicated new OpenClaw-specific tab/project scope and do not mix those flows into unrelated user flows. Do not default to cron; use cron only when the user explicitly asked for cron. Avoid hidden cross-tool state and document the decision in memory/decisions.md.
```

## 4. Shared Codex Hygiene

Use this before changing anything under `/root/.codex`.

```text
Inspect `/root/.codex` as shared host context, not repo-owned state. Summarize only the safe facts needed for this task. Prefer local repo docs, workspace files, or CLI overrides over changing the global Codex CLI config. If a global change still looks necessary, stop and justify it explicitly before doing it.
```

## 5. Cross-Agent Bridge Design

Use this when OpenClaw needs to interact with another long-running agent or service.

```text
Assume there is no invisible bot-to-bot magic. Design an explicit bridge using Node-RED, `openclaw agent --message ... --deliver`, or a small documented script. Include loop-prevention rules, ownership of config, and where the resulting operational knowledge should be saved.
```

## 6. Same-tab neighboring agent control

Use this when the user wants you to make text or a command appear in an already-running neighboring webterminal tab they are watching live.

```text
Resolve the target from `/opt/claude-vnc-terminal/data/terminal-state.json`, then resolve the live PTY from `/proc/<pid>/cwd`, `/proc/<pid>/fd/0`, and `/proc/<pid>/cmdline`. Use `scripts/find-live-terminal.py` and `scripts/write-live-terminal.sh` when available. Do not substitute OpenClaw TUI, `/codex resume`, WebSocket/API detours, a new side-channel session, or a replacement agent when the user explicitly wants the already-visible tab.
```
