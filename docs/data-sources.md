# Data Sources

This repo is an operator layer around OpenClaw. A fresh installer must read live host state and repo-managed docs before it changes the machine.

## Read Order

Read these sources before bootstrap:

1. `README.md`
2. `QUICKSTART.md`
3. `docs/install-runbook.md`
4. `docs/shared-host-context.md`
5. `docs/agent-topology.md`
6. `docs/data-sources.md`
7. `docs/memory-architecture.md`
8. `docs/model-policy.md`
9. `docs/installer-capability-contract.md`
10. `docs/stt-path.md`
11. `docs/lessons-learned.md`
12. `workspace/BOOTSTRAP.md`
13. `workspace/MEMORY.md`

## Live Host Evidence

The installer must inspect the real host, not rely only on static repo docs.

Primary live sources:

- `whoami`
- `pwd`
- `echo "$HOME"`
- `uname -a`
- `id`
- `ls /home`
- `systemctl is-system-running || true`
- `cat /opt/claude-vnc-terminal/data/terminal-state.json 2>/dev/null || true`
- `codex login status`
- `which codex || true`
- `which git || true`
- `which node || true`
- `which npm || true`
- `which python3 || true`
- `ps -ef | rg -i 'openclaw|node-red|codex|tmux'`
- `tmux ls 2>/dev/null || true`
- `<REPO_ROOT>/scripts/agent-landscape.sh`

## Static Sources

Static repo docs explain the intended operating model. They do not replace live inspection.

- `docs/shared-host-context.md` explains shared host services.
- `docs/agent-topology.md` explains known roots and tab rediscovery rules.
- `docs/memory-architecture.md` defines Level-1 memory.
- `docs/model-policy.md` defines the allowed model baseline.
- `docs/installer-capability-contract.md` defines what an installer may claim.
- `docs/stt-path.md` defines local STT validation.

## Source Precedence

Use this order when facts conflict:

1. Live host evidence.
2. Existing valid install state under the chosen owner root.
3. Repo-managed docs and scripts.
4. Official OpenClaw docs/source.
5. Historical notes.

Do not copy private memory or owner-specific state from another machine unless the user explicitly provides it.
