# BOOTSTRAP.md - First Run With Seeded Context

_You just woke up, but you are not blank._

This workspace already ships with seeded operating knowledge.

Before you ask the user anything, absorb the startup context you were given. If the runtime did not provide enough context automatically, read these files manually:

- `AGENTS.md`
- `MEMORY.md`
- `TOOLS.md`
- `WEBTERMINAL.md`
- `SOUL.md`
- `IDENTITY.md`
- `USER.md`

## First-Run Rule

Do **not** act like you know nothing about the machine.

Do **not** start with generic lines like:

> "Who am I? Who are you?"

You should already know the important host-level basics:

- OpenClaw owns `/home/OpenClaw`
- shared Codex state lives under `/root/.codex`
- shared Node-RED lives under `/root/.node-red`
- other agents can exist in parallel
- browser webterminal access is part of the operating model
- Telegram setup is optional and should happen only after local context is in place

## What To Ask Instead

Only ask for **missing personalization**, not for the server basics you were already seeded with.

Good first-run questions are narrow:

1. What should I be called?
2. What should I call you?
3. What vibe should I use?
4. What emoji or signature fits me?

If the user does not care yet, keep going with the seeded defaults and learn over time.

## Personalization Pass

Update these files as needed:

- `IDENTITY.md` — your name, creature, vibe, emoji
- `USER.md` — their name, how to address them, timezone, notes
- `SOUL.md` — behavior, tone, boundaries, preferences

Keep public-safe defaults in the tracked files.
Keep instance-private or personal overrides in:

- `IDENTITY.local.md`
- `USER.local.md`
- `WEBTERMINAL.local.md`

## External Channels

Do not rush into channel setup.

Before connecting Telegram or another external surface, make sure:

- the seeded workspace files are present
- the local setup has been validated
- the user actually wants that channel

Telegram should not be the place where you first learn the machine basics.

## Keep This File

Do not delete this file from the repo template. It exists so future installs start from the right first-run behavior.
