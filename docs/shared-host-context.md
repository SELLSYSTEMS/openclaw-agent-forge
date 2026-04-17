# Shared Host Context

This document describes the safe, durable context that future agents should know about this machine without leaking secrets into the public repository.

## Purpose

OpenClaw lives in `/home/OpenClaw`, but it is not the only AI system on the host.

Future agents need to understand four different context layers:

1. Public repo context
2. Repo-local OpenClaw context
3. Shared host services
4. Local-only secrets and owner-specific identifiers

## 1. Public Repo Context

The public GitHub repo is the durable source of truth for:

- bootstrap scripts
- operating rules
- safe architecture notes
- lessons learned
- reproducible prompts and workflows

The public repo is not a place for:

- tokens
- passwords
- owner-specific Telegram IDs
- gateway auth material
- chat transcripts that reveal private data

## 2. Repo-Local OpenClaw Context

OpenClaw-owned paths:

- install prefix: `/home/OpenClaw/.openclaw`
- runtime home: `/home/OpenClaw/.openclaw-home`
- launcher: `/home/OpenClaw/bin/openclaw-local`
- workspace: `/home/OpenClaw/workspace`
- memory: `/home/OpenClaw/memory`

OpenClaw defaults in this repo:

- primary model: `codex-cli/gpt-5.4`
- gateway mode: `local`
- gateway bind: `loopback`
- Telegram is configured via a local `tokenFile`, not tracked secrets

## 3. Shared Host Services

### Shared Codex CLI Home

Shared Codex CLI state currently lives under `/root/.codex`.

Useful read-first files:

- `/root/.codex/config.toml`
- `/root/.codex/history.jsonl`
- `/root/.codex/logs_2.sqlite`
- `/root/.codex/state_5.sqlite`

Operational rule:

- read shared Codex context when it helps
- do not mutate global Codex config casually from this repo
- prefer local repo docs, local workspace files, or CLI overrides when you need repo-specific behavior

### Shared Node-RED Service

Node-RED currently lives under `/root/.node-red`.

Useful read-first files:

- `/root/.node-red/settings.js`
- `/root/.node-red/flows.json`
- `/root/.node-red/package.json`

Local inspection on this host shows:

- `flowFile` points to `flows.json`
- `flowFilePretty` is enabled
- `adminAuth` is configured
- `editorTheme.projects` is configured

Operational assumption for this server class:

- Node-RED should be treated as installed and shared by default
- future agents should assume it exists even when the initial flows are mostly empty

Operational rule:

- treat Node-RED as the preferred automation fabric when a workflow needs repeatability, fan-out, or a human-readable flow diagram
- do not copy passwords, hashes, or credentials into tracked docs

### Other Active Agents

This host can have multiple long-running terminal agents at once.

There is also a concrete webterminal implementation on this host:

- implementation root: `/opt/claude-vnc-terminal`
- tab/session state file: `/opt/claude-vnc-terminal/data/terminal-state.json`

That file stores tab metadata such as:

- tab name
- working directory
- provider
- created/updated timestamps

Known current roots:

- `/home/admin` → Default AI
- `/home/langchain` → learnLangChain
- `/home/udacity` → learnUdacity
- `/home/OpenClaw` → OpenClaw

Practical discovery commands:

```bash
/home/OpenClaw/scripts/agent-landscape.sh
ps -ef | rg -i 'codex|openclaw|node-red|tmux'
tmux ls
```

Practical direct inspection for webterminal tabs:

```bash
cat /opt/claude-vnc-terminal/data/terminal-state.json
```

## 4. Local-Only Secrets And IDs

Keep local-only material out of Git:

- `.openclaw-home/secrets/`
- `workspace/*.local.md`
- `memory/references/local-only/`

If a future agent needs sensitive machine-specific facts, store them there and reference only the path conventions in the public docs.

Instance-specific browser-terminal URLs belong there too. The public repo should document the rule, not the live URL.

## Orchestrator Stance

For this repo, OpenClaw should be treated as the main orchestrator.

- OpenClaw owns the repo-local agent workflows
- Codex CLI provides the default model/auth execution path
- Node-RED is preferred for durable automations and bridge logic

That separation keeps the machine understandable:

- public-safe knowledge in GitHub
- repo-local behavior in `/home/OpenClaw`
- shared host services in `/root/.codex` and `/root/.node-red`
- sensitive material in ignored local paths
