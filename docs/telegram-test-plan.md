# Telegram Test Plan

This is the shortest safe path to wire a test Telegram bot into the local OpenClaw gateway.

## Current Local Status

- OpenClaw runtime is isolated under `<REPO_ROOT>/.openclaw-home`
- primary model floor is `gpt-5.5` with Codex CLI as the intended backend path
- gateway target is local loopback
- Codex CLI auth is the intended path, not `OPENAI_API_KEY`
- Telegram bot credentials should live only in `<REPO_ROOT>/.openclaw-home/secrets/`
- Seeded workspace knowledge should already be in place before Telegram is connected

## What Is Needed From The User

1. A Telegram bot token from `@BotFather`
2. Whether the test surface is:
   - DM-only
   - a specific group or forum topic
3. If group testing is needed:
   - add the bot to the target group
   - tell the bot to start
4. Preferred access policy:
   - quick DM pairing only
   - durable allowlist with your numeric Telegram user ID

## Recommended Test Order

1. Confirm the seeded workspace context exists and the setup is validated.

2. Start the local gateway:

```bash
./scripts/install-gateway-systemd.sh
./scripts/gateway-systemd-status.sh
./bin/openclaw-local gateway probe --timeout 20000
```

If systemd is unavailable, use the tmux fallback instead:

```bash
./scripts/start-gateway-tmux.sh
```

3. Add the Telegram channel account:

```bash
./bin/openclaw-local channels add --channel telegram --name test-telegram --token-file /path/to/bot.token
```

Recommended local path:

```bash
<REPO_ROOT>/.openclaw-home/secrets/<bot-name>.token
```

4. DM the bot from the target Telegram account.
5. After the gateway is already running, send a fresh `/start` or plain-text message so polling definitely sees a live inbound event.

6. Inspect logs or updates to capture the numeric Telegram user ID if durable allowlisting is needed.

7. Keep one of these policies:

- `dmPolicy: pairing` for the fastest DM smoke test
- `dmPolicy: allowlist` plus `allowFrom: ["<numeric-user-id>"]` for a durable owner-only bot

Recommended steady state after the first successful owner DM:

- approve the initial pairing if the bot started in pairing mode
- capture the owner's numeric Telegram user ID
- move the bot to `dmPolicy: allowlist`
- keep the numeric owner ID only in local runtime config, not in tracked repo files

8. For groups, allow the group separately and keep sender authorization explicit:

- add the negative Telegram group ID under `channels.telegram.groups`
- keep your numeric user ID in `allowFrom` or `groupAllowFrom`

## Notes

- Telegram should not be used as the place where OpenClaw first learns the server architecture, shared agent roots, or host rules; that knowledge belongs in the seeded workspace files.
- Pairing grants DM access only.
- For groups, sender authorization still comes from explicit config allowlists.
- If the same owner should work in both DM and groups, store the numeric Telegram user ID in `channels.telegram.allowFrom`.
- Group replies require mention by default unless group config relaxes it.
- Never store the Telegram bot token in tracked repo files. Keep only the secret file path and safe operational notes in Git.
- Never store the owner's numeric Telegram user ID in tracked docs when the repo is public. Keep it only in local runtime config.
