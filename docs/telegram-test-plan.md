# Telegram Test Plan

This is the shortest safe path to wire a test Telegram bot into the local OpenClaw gateway.

## Current Local Status

- OpenClaw runtime is isolated under `/home/OpenClaw/.openclaw-home`
- primary model is `codex-cli/gpt-5.4`
- gateway target is local loopback
- Codex CLI auth is the intended path, not `OPENAI_API_KEY`

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

1. Start the local gateway:

```bash
/home/OpenClaw/scripts/start-gateway-tmux.sh
/home/OpenClaw/bin/openclaw-local gateway probe
```

2. Add the Telegram channel account:

```bash
/home/OpenClaw/bin/openclaw-local channels add --channel telegram --name test-telegram --token-file /path/to/bot.token
```

3. DM the bot from the target Telegram account.

4. Inspect logs or updates to capture the numeric Telegram user ID if durable allowlisting is needed.

5. Keep one of these policies:

- `dmPolicy: pairing` for the fastest DM smoke test
- `dmPolicy: allowlist` plus `allowFrom: ["<numeric-user-id>"]` for a durable owner-only bot

6. For groups, allow the group separately and keep sender authorization explicit:

- add the negative Telegram group ID under `channels.telegram.groups`
- keep your numeric user ID in `allowFrom` or `groupAllowFrom`

## Notes

- Pairing grants DM access only.
- For groups, sender authorization still comes from explicit config allowlists.
- If the same owner should work in both DM and groups, store the numeric Telegram user ID in `channels.telegram.allowFrom`.
- Group replies require mention by default unless group config relaxes it.
