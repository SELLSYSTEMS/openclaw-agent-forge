# Local Memory Vault

This vault is optimized for Codex/OpenClaw local work.

## Structure

- `active-context.md` - the current state, constraints, next steps, and active assumptions
- `decisions.md` - durable decisions and their rationale
- `references/` - stable facts worth reusing
- `projects/` - project-specific notes
- `inbox/` - quick captures before they are promoted elsewhere

## Best Practice Choice

Recommended default:

1. Markdown files as the source of truth.
2. Fast search with `rg` or `bin/memory-find`.
3. Periodic summarization from `inbox/` into `active-context.md`, `decisions.md`, or `projects/`.

Why not start with a vector DB:

- it adds another stateful service
- embeddings become stale when notes change
- retrieval errors are harder to debug than plain text search
- local files are easier for agents to inspect directly

When to add a vector DB:

- you have thousands of notes
- you need semantic retrieval across noisy text
- keyword search is no longer enough

If you want a GUI, point Obsidian at `/home/OpenClaw/memory`. Use it as a viewer and editor, not as a second source of truth.
