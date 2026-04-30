# Portable Level-1 Memory Architecture

Purpose: give OpenClaw a portable first memory layer that survives across instances, agents, and fresh installs without depending on one oversized prompt.

## Level-1 scope

Level-1 memory is the portable, GitHub-safe layer:

- contracts
- startup read order
- discovery methods
- public-safe long-term operating facts
- install-time requirements

It is not:

- raw local notes
- secrets
- instance-private URLs/IDs
- live tab names/order/path snapshots
- vector/DB memory layers

## Canonical layout

- `docs/` → global OpenClaw contracts and architecture
- `BOOTSTRAP.md` → mandatory startup read order
- `MEMORY.md` → public-safe long-term OpenClaw memory
- `TOOLS.md` → discovery methods and operating notes
- `*.local.md` → instance-private overrides
- `memory/` → raw local notes (gitignored)

## Dynamic topology rule

Webterminal topology is dynamic:

- tab names can change
- working directories can change
- tab order can change
- neighboring agent roots can differ by instance

Therefore Level-1 memory must preserve discovery methods, not stale live values.

Canonical live sources:

- `/opt/claude-vnc-terminal/data/terminal-state.json`
- `<REPO_ROOT>/scripts/agent-landscape.sh`

Never treat cached tab names, paths, or order as source of truth.

## Live webterminal control rule

If the requirement is to interact with an already-running agent live in the same webterminal tab, use one canonical control path:

1. resolve target tab/cwd from `/opt/claude-vnc-terminal/data/terminal-state.json`
2. resolve the live `/dev/pts/N` from `/proc/<pid>/cwd`, `/proc/<pid>/fd/0`, and `/proc/<pid>/cmdline`
3. write directly to that PTY

Do not substitute these with:

- `/codex resume`
- ACP/new side-channel session
- file mailbox
- spawning a separate replacement agent
- WebSocket/API control story
- tmux bridge unless the actual tested path on that host is explicitly tmux-backed

Those do not satisfy the same-live-tab requirement.

## No-sandbox requirement

When topology discovery or live webterminal control is required, the operator path must not use a sandbox mode that blocks:

- `/opt/claude-vnc-terminal/data/terminal-state.json`
- the corresponding webterminal server-side API/PTY path

Do not continue pretending topology/control is solved if the active runtime cannot read the live topology source or reach the live PTY path.

## Agent startup rule

Before acting on multi-agent topology, an agent must re-ground itself in:

1. current runtime surface
2. current owner context
3. current live tab registry
4. current shared-agent landscape
5. current memory scope (global vs local vs private)

## Install/bootstrap requirement

During install or bootstrap, OpenClaw must seed and link the Level-1 memory layer before first user chat:

- `BOOTSTRAP.md`
- `MEMORY.md`
- `TOOLS.md`
- `docs/memory-architecture.md`
- other linked capability docs such as `docs/installer-capability-contract.md` and `docs/stt-path.md`

The installer must also ensure:

- local/private memory paths are gitignored
- topology discovery commands are present and documented
- startup docs point to each other clearly

## Validation rule

An install is not fully ready unless it can show:

- the Level-1 memory files exist
- they are linked together
- dynamic topology discovery uses live host evidence
- local/private memory is separated from tracked docs

## Behavior rule

For critical facts, store:

- the rule
- the scope
- where to rediscover the live value

Do not store changing live values as if they were durable truth.

See also:

- `docs/data-sources.md`
- `BOOTSTRAP.md`
- `MEMORY.md`
- `TOOLS.md`
- `docs/model-policy.md`
- `docs/installer-capability-contract.md`
- `docs/stt-path.md`
