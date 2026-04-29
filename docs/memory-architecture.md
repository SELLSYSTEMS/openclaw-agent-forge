# Memory Architecture

This repo uses a Level-1 memory architecture: simple, local, inspectable files before any vector database or external memory service.

## Level-1 Memory Definition

Level-1 memory is the minimum durable context a fresh OpenClaw install must have before first chat.

It consists of:

- `workspace/AGENTS.md` - behavior rules for future agents.
- `workspace/BOOTSTRAP.md` - first-run expectations.
- `workspace/MEMORY.md` - public-safe seeded operating memory.
- `workspace/TOOLS.md` - tool and command assumptions.
- `workspace/WEBTERMINAL.md` - webterminal topology rules.
- `workspace/SOUL.md` - identity and operating style seed.
- `workspace/IDENTITY.md` - role and name seed.
- `workspace/USER.md` - user-facing assumptions that are safe to track.
- `memory/README.md` - memory vault map.
- `memory/active-context.md` - current public-safe operating context.
- `memory/decisions.md` - durable decisions.

## Install Rule

Before the first chat, Telegram pairing, or gateway handoff, the installer must confirm these files exist and are readable.

If any required Level-1 file is missing, stop and repair the workspace seed before proceeding.

## Linkage Rule

The workspace and memory vault must be linked by content, not symlink tricks:

- `workspace/MEMORY.md` should point future agents to `memory/`.
- `memory/README.md` should explain how to promote temporary notes into durable memory.
- `memory/active-context.md` should summarize the current install model.
- `memory/decisions.md` should record the model/auth/topology decisions.

## Privacy Boundary

Tracked memory must stay public-safe.

Do not commit:

- passwords
- API keys
- Telegram bot tokens
- Telegram user IDs
- private URLs
- private transcripts
- owner-specific secrets

Use local-only files such as `*.local.md` for instance-private notes.
