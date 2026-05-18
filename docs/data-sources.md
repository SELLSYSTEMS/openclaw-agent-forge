# Data Sources / Source of Truth

Use the thinnest prompt possible. Put durable guidance here and make agents read it.

## Priority order

1. GitHub-tracked contracts/docs
2. Live host evidence
3. Local/private overrides
4. Prompt text only as a router to the above

## GitHub-tracked contracts/docs

- `docs/memory-architecture.md`
- `docs/model-policy.md`
- `docs/installer-capability-contract.md`
- `docs/stt-path.md`
- `docs/artifact-delivery-policy.md`
- `BOOTSTRAP.md`
- `MEMORY.md`
- `TOOLS.md`

These define durable rules, scope, startup order, model policy, memory organization, and capability requirements.

## Live host evidence

For topology / neighboring agents / webterminal:

- `/opt/claude-vnc-terminal/data/terminal-state.json`
- `<REPO_ROOT>/scripts/agent-landscape.sh`
- `/proc/<pid>/cwd`
- `/proc/<pid>/fd/0`
- `/proc/<pid>/cmdline`
- `/dev/pts/*`
- process list / tmux state / actual runtime state

Do not replace live host evidence with stale copied examples.

For artifact delivery:

- project repo deployment/domain docs for the target artifact
- nginx or app vhost config for public download surfaces
- destination system docs or live config for current upload limits
- `<REPO_ROOT>/scripts/check-artifact-delivery.sh`
- `<REPO_ROOT>/scripts/check-telegram-media-size.sh`

## Local/private overrides

Use local/private files for instance-specific facts:

- `*.local.md`
- gitignored local notes
- runtime-local state

Do not push these into tracked docs.

## Prompt rule

Prompt text should:

- tell agents what to read
- point to live sources
- avoid becoming the only place where critical knowledge lives

## Memory rule

Store:

- rules
- scopes
- rediscovery methods

Do not store dynamic live values as durable truth.

See also:

- `docs/memory-architecture.md`
- `docs/model-policy.md`
- `BOOTSTRAP.md`
- `MEMORY.md`
- `TOOLS.md`
