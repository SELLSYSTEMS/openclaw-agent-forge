# Codex CLI TUI

This document explains the OpenAI Codex CLI terminal UI on this host and how future agents should enable or use it safely.

Official sources checked for this runbook:

- `https://developers.openai.com/codex/cli`
- `https://github.com/openai/codex`

## What The TUI Is

OpenAI's current Codex CLI docs describe the CLI as a local terminal client for pairing with Codex, and the official GitHub repo says to install Codex and then simply run `codex` to get started.

The installed CLI on this host matches that model exactly. Local help confirms:

- if no subcommand is specified, options are forwarded to the interactive CLI
- `codex` starts the interactive TUI

## Basic Start

From a project root:

```bash
codex
```

From a specific folder:

```bash
codex -C /home/admin
codex -C /home/langchain
codex -C /home/udacity
codex -C /home/OpenClaw
```

## What Must Be Installed On The Server

There is no separate Codex TUI package to install.

To enable the Codex TUI for terminal agents on a server, you need:

- the `codex` CLI itself installed and on `PATH`
- a valid login for the Unix account that runs those agent sessions
- a working `~/.codex` directory for that same account
- a terminal surface that can display interactive TUIs

Official install paths from the OpenAI docs and official GitHub repo:

- `npm install -g @openai/codex`
- the official binary releases from `openai/codex`

On this host class, the practical extra rule is:

- in browser terminals, prefer `codex --no-alt-screen`

If all terminal tabs share the same Unix user, one shared `~/.codex` login is enough for all of them.
If future agents run under different Unix users, each user needs its own Codex login state.

## Authentication

Preferred path on this host:

```bash
codex login status
```

Current local state has already been verified as:

- `Logged in using ChatGPT`

If a future machine is not logged in yet, use the supported login flow:

```bash
codex login
```

You can also simply run `codex` and follow the first-run sign-in prompt.

This repo still prefers ChatGPT/Codex CLI reuse over `OPENAI_API_KEY`.
API-key login exists, but it is not the default operating model for `/home/OpenClaw`.

## Best Flag For Webterminal

In browser terminals or strict multiplexers, prefer:

```bash
codex --no-alt-screen
```

Why:

- it keeps terminal scrollback visible
- it is better suited to webterminal-style environments

## Useful TUI Flags

- `--no-alt-screen` → keep scrollback instead of using an alternate screen
- `-C <DIR>` → start the TUI in a specific working root
- `-m <MODEL>` → override the model
- `-p <PROFILE>` → use a named config profile from `~/.codex/config.toml`
- `-s <MODE>` → choose sandbox mode
- `-a <POLICY>` → choose approval behavior
- `--full-auto` → convenience shortcut for a low-friction sandboxed mode
- `--remote <ADDR>` → connect the TUI to a remote app server websocket
- `--remote-auth-token-env <ENV_VAR>` → pass bearer auth to a remote app server
- `--search` → enable live web search
- `--add-dir <DIR>` → add extra writable directories

## Current Shared Host Defaults

The shared global Codex config at `/root/.codex/config.toml` currently shows:

- `approval_policy = "on-request"`
- `sandbox_mode = "workspace-write"`
- `model = "gpt-5.4"`
- `model_reasoning_effort = "xhigh"`

Trusted project roots currently include:

- `/home/admin`
- `/home/langchain`
- `/home/udacity`
- `/home/STONfiHackathon`
- `/home/OpenClaw`
- `/home/OpenClaw/workspace`
- `/home/freelance`

Operational rule:

- read this shared config first
- do not casually rewrite global Codex settings from the OpenClaw repo

## Relationship To OpenClaw

- Codex CLI TUI is the main interactive surface for the other terminal agents
- OpenClaw uses `codex-cli/gpt-5.4` as its default model path
- OpenClaw should understand Codex CLI TUI behavior, but keep its own repo-local orchestration rules under `/home/OpenClaw`

## Official References

- Codex CLI docs: `https://developers.openai.com/codex/cli`
- Official GitHub repo: `https://github.com/openai/codex`
- Codex with your ChatGPT plan: `https://help.openai.com/en/articles/11369540-using-codex-with-your-chatgpt-plan/`
