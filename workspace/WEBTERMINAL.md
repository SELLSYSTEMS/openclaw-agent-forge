# WEBTERMINAL.md

This host class commonly uses a browser webterminal as the main human-to-agent entrypoint.

## Rule

The exact webterminal URL is instance-specific.

Do not hardcode the live URL into the public repository.

## Local-Only Path

If present, read:

- `WEBTERMINAL.local.md`

That local-only file may contain:

- the current instance URL
- safe access notes for this machine
- any local conventions that should not be published to GitHub

## Why

Different instances of the same server pattern can have different webterminal addresses.

Future agents should understand that webterminal access is part of the operating model, while still keeping the exact live URL out of the public repo.
