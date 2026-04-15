# GitHub Publish Plan

Recommended repository name:

- `openclaw-agent-forge`

Recommended description:

- `Codex-built bootstrap for a live OpenClaw AI server and multi-agent workspace.`

Recommended visibility:

- `public` if the goal is reuse by future agents on other machines
- `private` if the repo will contain environment-specific notes later

Recommended remote:

```bash
git remote add origin https://github.com/ryuriymega/openclaw-agent-forge.git
git push -u origin main
```

Automated publish path:

```bash
GITHUB_TOKEN=... /home/OpenClaw/scripts/publish-github.sh ryuriymega openclaw-agent-forge public
```

## Why This Name

- `OpenClaw` keeps the product identity explicit
- `Agent` makes the multi-agent operating model clear
- `Forge` implies bootstrap, assembly, and durable infrastructure

## What Must Stay Out Of Git

- `.openclaw/`
- `.openclaw-home/`
- transient inbox captures unless curated
- machine-local scratch files

## Current Known Blocker

If plain `git push` fails with:

```text
fatal: could not read Username for 'https://github.com': No such device or address
```

the shell is not authenticated to GitHub. Use `scripts/publish-github.sh` with `GITHUB_TOKEN` or `GH_TOKEN`.
