# Local Langfuse Host Readiness

Langfuse observability and OpenClaw's Codex/Telegram runtime are separate systems. A missing tracing UI does not explain a final reply suppressed inside OpenClaw. Repair and verify them separately.

## Domain Is Not A Startup Prerequisite

Start with a loopback-only service and verified local ingestion. A domain is only needed later if the owner wants convenient remote browser access. Agree the hostname, TLS and access control before exposure; keep databases, object storage and ingestion internals private. Never publish credentials in Git or chat.

The [official Compose guide](https://langfuse.com/self-hosting/deployment/docker-compose) describes local deployment; [self-hosting documentation](https://langfuse.com/self-hosting) covers other options. Use the project's reviewed, pinned deployment instead of overwriting it with a sample.

## Check The Actual Host

Discover the project, service owner and virtualization first. Do not install a second daemon, replace shared databases, start every cached container or reload the product backend as a diagnostic shortcut.

Require a real minimal container to start under the intended isolation policy, not just valid YAML or a healthy Docker daemon. Check available memory/disk, per-service ceilings, private networking, loopback bindings and credentials in ignored mode-0600 files. Use the existing project's `preflight` and `isolation-check` before its `resume`/`start`; inspect current helper behavior and paths first.

Tracing readiness is not approval for a product model/provider change, paid inference or backend activation.

## Nested LXC Failure Seen On 2026-09-13

A bounded, no-network/no-secret, read-only container with dropped capabilities failed before its entrypoint:

```text
error mounting "proc" to rootfs at "/proc": permission denied
```

The instance was an unprivileged LXC guest. Creating a mount namespace alone succeeded, but actual OCI startup did not. Do not generalize this to all shell commands being blocked or diagnose it as Codex `bwrap`, DNS, credentials, RAM or a missing domain.

The exact outer LXC policy was not visible from the guest. Guest root does not imply parent kernel/container control. Ask for the hosting panel/provider or an administrator who can validate nested OCI support. Do not claim a specific nesting, AppArmor or seccomp setting is proven without outer-host evidence. Do not bypass this by downgrading the runtime or making every container privileged.

There were no running containers before this diagnostic. Docker/containerd were started only for the probe and returned to their prior inactive state. Images, volumes, credentials and the working backend were preserved.

## Resume Safely

1. After the external blocker is resolved, recheck active work/resources and repeat the same minimal probe.
2. Start only the project-scoped pinned stack through its reviewed lifecycle helper.
3. Verify every dependency, local web health and authenticated metadata-only ingest/readback. Green unit tests are not deployment proof.
4. Obtain a hostname only if remote access is requested; configure authenticated TLS separately. Keep application traffic on the approved local endpoint.
5. Record actual live status and remaining approvals locally; publish only generalized lessons and tests.
