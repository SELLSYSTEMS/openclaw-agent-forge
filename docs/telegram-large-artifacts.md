# Telegram Large Artifacts

OpenClaw can attach files to Telegram replies with `MEDIA:<path-or-url>`, but Telegram Bot API delivery has provider limits.

## Rule

Before using `MEDIA:` for a local artifact, check the file size.

```bash
./scripts/check-telegram-media-size.sh /path/to/file.apk
```

Stable default:

- below `45,000,000` bytes: OK to attach
- `45,000,000` to `50,000,000` bytes: risky, prefer a link/path
- above `50,000,000` bytes: do not attach with `MEDIA:` through Telegram Bot API

## Why

An Android debug APK of `77,829,119` bytes caused Telegram `sendDocument` to fail with:

```text
413: Request Entity Too Large
```

OpenClaw had already generated the final answer, but because the `MEDIA:` attachment failed, Telegram showed a generic failure message instead of the useful text.

## Required Behavior

For large APKs, archives, videos, model files, or build artifacts:

- do not include `MEDIA:<path>` in the final Telegram reply
- send the final text summary normally
- include the local file path
- offer a safer delivery path such as GitHub Release asset, approved web link, shared Node-RED/file server flow, or manual retrieval from the server

Do not expose local build artifacts through a public URL unless the user explicitly approves that exposure.

## Current Reference Incident

The `interviewcoach-alpha-debug.apk` artifact exceeded the Telegram Bot API direct upload limit:

```text
77829119 /home/OpenClaw/workspace/deliverables/interviewcoach-alpha-debug.apk
77829119 /home/interviewcoach/ai-engineer-interview-coach/android/app/build/outputs/apk/debug/app-debug.apk
```

The correct future response is to report the build result and path, not to attach this APK directly through Telegram.
