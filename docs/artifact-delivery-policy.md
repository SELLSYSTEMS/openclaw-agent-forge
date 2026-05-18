# Artifact Delivery Policy

OpenClaw must treat artifact delivery as an operational workflow, not as a best-effort chat attachment.

Artifacts include APKs, archives, reports, media files, datasets, logs, dashboard exports, generated documents, and any other file the user expects to receive or open.

## Non-Negotiable Rule

Before any agent sends, uploads, publishes, links, or attaches an artifact through any system, run a delivery preflight for that destination.

The preflight must check:

- destination system and actual transport
- current file size
- file type and extension
- destination size/type limits
- auth and exposure rules
- safe fallback path if direct delivery is not allowed
- final URL, upload result, or local path before claiming success

This rule is not Telegram-specific. It applies to Telegram, GitHub, nginx or app download links, Node-RED flows, local filesystem handoff, email, cloud storage, dashboards, and any future channel.

## Decision Flow

1. Determine the user-facing destination.
2. Determine the real transport used by that destination.
3. Check the artifact against the transport's current limits.
4. If direct delivery is safe, attach or upload it.
5. If direct delivery is unsafe, use an approved fallback such as a verified public link, GitHub Release asset, local server path, or another user-approved channel.
6. If the fallback exposes a private/local artifact publicly, ask the user before publishing.
7. Final response must state the delivery method, path or URL, and any caveat such as "local path only" or "link verified".

## Helper

Use the target-aware helper when possible:

```bash
./scripts/check-artifact-delivery.sh --target telegram-bot /path/to/file.apk
./scripts/check-artifact-delivery.sh --target public-link /path/to/file.apk
./scripts/check-artifact-delivery.sh --target local-path /path/to/file.apk
```

For systems with limits that can change, the helper intentionally tells the agent what live verification is still required instead of hardcoding a stale universal number.

## Known Transport Notes

- Telegram Bot API direct document upload has a practical 50 MB limit for this setup. Use `scripts/check-telegram-media-size.sh` before any Telegram `MEDIA:` reply.
- Public nginx or application download links require vhost/path verification and an explicit exposure decision. Verify with `curl -I` or an equivalent request before giving the URL to the user.
- GitHub is appropriate for source and sometimes Release assets. Check current GitHub limits and repo permissions before using it for generated binaries. Do not commit large generated artifacts unless the repo intentionally tracks them.
- Node-RED is preferred for durable automations, bridges, and human-visible workflow diagrams, but flow/request/body limits and credential handling must still be checked before pushing files through it.
- Local filesystem paths are acceptable only when the user or the next agent has server access. If the user is on a phone/chat client, a local path is not the same as delivered.

## Failure Handling

Do not let delivery failure hide completed work.

If a build, export, or report generation succeeded but the final delivery failed, the agent must report:

- the work status
- artifact path
- destination error
- safe next delivery option

The user should never see only a generic failure when the useful work already completed.
