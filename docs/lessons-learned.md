# Lessons Learned

## Installation

- The official installer is the correct starting point for a local prefix install.
- A local prefix is better than a global install on a shared machine.
- The installed CLI was verified as `OpenClaw 2026.4.12 (1c0672b)` during bootstrap.

## Isolation

- OpenClaw config normally lives under `~/.openclaw/openclaw.json`.
- For this setup, `OPENCLAW_HOME=/home/OpenClaw/.openclaw-home` is mandatory.
- Without isolated runtime home, sessions and config can mix with unrelated agent state.

## Memory

- Local Markdown files are the best default memory backend here.
- `ripgrep` is enough for the current scale.
- Obsidian is acceptable as a user interface over the same folder.
- A vector database should be added only after keyword retrieval becomes insufficient.

## Tooling Mistakes To Avoid

- Do not commit the installed runtime tree.
- Do not assume helper scripts work without a smoke-test.
- Do not store durable decisions only in chat history; promote them into tracked files.
- Do not make a GitHub repo depend on local state that cannot be rebuilt from scripts.
- If the shell sandbox throws `bwrap: Failed to make / slave: Permission denied`, treat it as an execution environment issue and rerun with escalation.
