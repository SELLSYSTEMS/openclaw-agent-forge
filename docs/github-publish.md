# GitHub Publish Plan

Recommended repository name:

- `openclaw-agent-forge`

Canonical owner:

- `SELLSYSTEMS`

Recommended description:

- `Codex-built bootstrap for a live OpenClaw AI server and multi-agent workspace.`

Recommended visibility:

- `public` if the goal is reuse by future agents on other machines
- `private` if the repo will contain environment-specific notes later

Recommended remote:

```bash
git remote add origin https://github.com/SELLSYSTEMS/openclaw-agent-forge.git
git push -u origin main
```

Automated publish path:

```bash
GITHUB_TOKEN=... /home/OpenClaw/scripts/publish-github.sh SELLSYSTEMS openclaw-agent-forge public
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

## Notes

- This repository is already published at `https://github.com/SELLSYSTEMS/openclaw-agent-forge`.
- If `git push` fails, inspect `gh auth status -t` and verify the token or browser auth actually grants write access for the target organization repository.
