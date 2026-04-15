# Install Runbook

This runbook describes the local isolated OpenClaw installation pattern used in this repository.

## Target Layout

- install prefix: `/home/OpenClaw/.openclaw`
- runtime home: `/home/OpenClaw/.openclaw-home`
- launcher: `/home/OpenClaw/bin/openclaw-local`
- workspace: `/home/OpenClaw/workspace`
- memory vault: `/home/OpenClaw/memory`

## Why This Layout

- avoids collisions with other agents on the same machine
- keeps runtime state out of global home directories
- makes the setup reproducible from a clean checkout
- lets git track only scripts, docs, and memory structure

## Fresh Bootstrap

Run:

```bash
/home/OpenClaw/scripts/bootstrap-openclaw.sh
```

What it does:

1. Installs OpenClaw into `/home/OpenClaw/.openclaw` via the official installer.
2. Creates `/home/OpenClaw/.openclaw-home`.
3. Configures OpenClaw with `OPENCLAW_HOME=/home/OpenClaw/.openclaw-home`.
4. Sets `agents.defaults.workspace` to `/home/OpenClaw/workspace`.
5. Validates the resulting config.

## Validation

Run:

```bash
/home/OpenClaw/scripts/validate-local-setup.sh
```

Expected outcomes:

- `openclaw-local --version` prints a version
- `openclaw config validate` reports a valid config
- the configured workspace resolves to `/home/OpenClaw/workspace`

## Publishable Files

Commit these:

- docs
- scripts
- helper launchers
- memory structure and durable notes

Do not commit these:

- `.openclaw/`
- `.openclaw-home/`
- transient scratch files
- ad hoc inbox captures unless they were curated intentionally
