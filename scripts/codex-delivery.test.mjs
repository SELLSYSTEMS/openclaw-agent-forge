import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import os from "node:os";
import path from "node:path";
import { test } from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";
import vm from "node:vm";

// Exercise the installed, version-pinned code, not a reimplementation of it.
const dist = process.env.OPENCLAW_TEST_DIST ?? fileURLToPath(new URL(
  "../.openclaw/lib/node_modules/openclaw/dist/", import.meta.url,
));
function bundle(prefix, needle) {
  const matches = readdirSync(dist).filter((name) => name.startsWith(prefix) && name.endsWith(".js"))
    .map((name) => ({ name, source: readFileSync(path.join(dist, name), "utf8") }))
    .filter(({ source }) => source.includes(needle));
  assert.equal(matches.length, 1, `Expected one ${prefix} bundle containing ${needle}`);
  return matches[0];
}
function region(source, name) {
  const start = source.indexOf(`//#region ${name}\n`);
  assert.notEqual(start, -1, `Missing region ${name}`);
  const end = source.indexOf("//#endregion", start);
  assert.notEqual(end, -1);
  return source.slice(start, end);
}
async function importedBindings(source, names) {
  const bindings = {};
  for (const [, list, file] of source.matchAll(/import \{ ([^\n]+) \} from "(\.\/[^\"]+)";/g)) {
    for (const spec of list.split(", ")) {
      const [exported, local = exported] = spec.split(" as ");
      if (names.includes(local)) bindings[local] = (await import(pathToFileURL(path.join(dist, file))))[exported];
    }
  }
  for (const name of names) assert.notEqual(bindings[name], undefined, `Missing real binding ${name}`);
  return bindings;
}

const harness = bundle("harness-", "var CodexAppServerEventProjector = class");
const agent = bundle("agent-runner.runtime-", "async function buildReplyPayloads(params)");
const runner = bundle("pi-embedded-runner-", "recoveredPostAnswerCodexAppServerError");
const bot = bundle("bot-", 'import { n as deliverReplies,');
const { deliverReplies } = await importedBindings(bot.source, ["deliverReplies"]);
const diagnostics = [];
const Projector = vm.runInNewContext(`${region(harness.source, "extensions/codex/src/app-server/event-projector.ts")}
CodexAppServerEventProjector`, {
  isJsonObject: (value) => !!value && typeof value === "object" && !Array.isArray(value),
  formatErrorMessage$1: String,
  normalizeUsage: (usage) => usage,
  log: { info: (line) => diagnostics.push(line), warn: (line) => diagnostics.push(line) },
});
const payloadBindings = await importedBindings(agent.source, [
  "applyReplyThreading", "isRenderablePayload", "parseReplyDirectives", "SILENT_REPLY_TOKEN",
  "resolveSendableOutboundReplyParts", "stripHeartbeatToken", "resolveOriginMessageProvider",
  "resolveOriginMessageTo", "resolveOriginAccountId", "createBlockReplyContentKey",
  "isBunFetchSocketError", "formatBunFetchSocketError",
]);
const dedupeName = agent.source.match(/import\("(\.\/reply-payloads-dedupe\.runtime-[^\"]+)"\)/)?.[1];
assert.ok(dedupeName, "Missing dedupe runtime import");
const dedupeRuntime = await import(pathToFileURL(path.join(dist, dedupeName)));
const payloadSource = region(agent.source, "src/auto-reply/reply/agent-runner-payloads.ts")
  .replace(/import\("\.\/reply-payloads-dedupe\.runtime-[^\"]+"\)/, "Promise.resolve(dedupeRuntime)");
const buildReplyPayloads = vm.runInNewContext(`
${region(agent.source, "src/auto-reply/reply/reply-delivery.ts")}
${payloadSource}
buildReplyPayloads`, {
  ...payloadBindings, dedupeRuntime,
  logVerbose: (line) => diagnostics.push(line),
  defaultRuntime: { log: (line) => diagnostics.push(line) },
});
const telemetry = {
  didSendViaMessagingTool: false, messagingToolSentTexts: [], messagingToolSentMediaUrls: [],
  messagingToolSentTargets: [], toolMediaUrls: [], successfulCronAdds: 0,
};
function projector() {
  return new Projector({
    prompt: "Synthetic regression test", sessionId: "test-session", modelId: "gpt-6-astra",
    provider: "codex", model: {}, onAgentEvent() {},
  }, "test-thread", "test-turn");
}
function notify(p, method, params = {}) {
  return p.handleNotification({ method, params: { threadId: "test-thread", turnId: "test-turn", ...params } });
}
function complete(p, status = "completed", error = null) {
  return notify(p, "turn/completed", {
    turn: { id: "test-turn", status, error, items: [{ id: "final", type: "agentMessage", text: "Tests passed; work checkpoint saved." }] },
  });
}
const progress = "I am checking the current project checkpoint and running the build now.";
const final = "Implementation finished. All checks passed. The result is saved locally; no deployment was made.";
const basePayload = {
  payloads: [{ text: final }], modelProvider: "codex", messageProvider: "telegram",
  originatingChannel: "telegram", originatingTo: "test-owner", accountId: "default",
  messagingToolSentTexts: [progress],
  messagingToolSentTargets: [{ provider: "telegram", to: "test-owner", accountId: "default" }],
  blockStreamingEnabled: false, silentExpected: false,
};
async function payloads(overrides = {}) {
  return (await buildReplyPayloads({ ...basePayload, ...overrides })).replyPayloads;
}

test("retriable nested Codex errors do not poison a completed turn or transcript", async () => {
  const p = projector();
  await notify(p, "error", { error: { message: "Unable to verify model access right now" }, willRetry: true });
  assert.equal(p.buildResult(telemetry).promptError, null);
  await complete(p);
  const result = p.buildResult(telemetry);
  assert.equal(result.promptError, null);
  assert.equal(result.lastAssistant.stopReason, "stop");
  assert.equal(result.lastAssistant.codexTurnStatus, "completed");
  assert.equal(result.messagesSnapshot.at(-1).stopReason, "stop");
});
test("nested fatal error retains the real message before terminal failure", async () => {
  const p = projector();
  await notify(p, "error", { error: { message: "Usage limit reached" }, willRetry: false });
  assert.equal(p.buildResult(telemetry).promptError, "Usage limit reached");
  await complete(p, "failed", { message: "Usage limit reached" });
  const result = p.buildResult(telemetry);
  assert.equal(result.promptError, "Usage limit reached");
  assert.equal(result.lastAssistant.stopReason, "error");
  assert.equal(result.lastAssistant.codexTurnStatus, "failed");
});
test("terminal completion clears stale legacy notification errors", async () => {
  const p = projector();
  await notify(p, "error", { message: "codex app-server error" });
  await complete(p);
  assert.equal(p.buildResult(telemetry).promptError, null);
});
test("late, foreign and unscoped notifications cannot corrupt a turn", async () => {
  const p = projector();
  await notify(p, "error", { threadId: "foreign-thread", error: { message: "foreign" }, willRetry: false });
  await notify(p, "error", { turnId: "foreign-turn", error: { message: "foreign" }, willRetry: false });
  await p.handleNotification({ method: "error", params: { error: { message: "unscoped" }, willRetry: false } });
  assert.equal(p.buildResult(telemetry).promptError, null);
  await complete(p);
  await notify(p, "error", { error: { message: "late" }, willRetry: false });
  assert.equal(p.buildResult(telemetry).promptError, null);
});
test("timeout and interrupted turns remain interrupted, never recovered as success", async () => {
  const p = projector();
  p.markTimedOut();
  await complete(p);
  assert.equal(p.buildResult(telemetry).aborted, true);
  assert.equal(p.buildResult(telemetry).lastAssistant.stopReason, "aborted");
  assert.match(p.buildResult(telemetry).promptError, /timed out/);
  const interrupted = projector();
  await complete(interrupted, "interrupted");
  assert.equal(interrupted.buildResult(telemetry).aborted, true);
});
test("outer historical recovery cannot hide failed or timed out turns with partial text", () => {
  const expr = runner.source.match(/const recoveredPostAnswerCodexAppServerError = (Boolean\([^\n]+\));/)?.[1];
  assert.ok(expr, "Missing outer recovery guard");
  for (const status of ["failed", "interrupted", undefined]) {
    const assistant = { stopReason: "error", codexTurnStatus: status, content: [{ type: "text", text: progress }] };
    const recovered = vm.runInNewContext(expr, {
      promptError: "codex app-server turn failed", promptErrorSource: "prompt", aborted: false,
      currentAttemptAssistant: assistant, sessionLastAssistant: assistant,
      resolveFinalAssistantVisibleText: () => progress, formatErrorMessage: String,
    });
    assert.equal(recovered, false, `Must not recover terminal status ${status}`);
  }
  const previous = { stopReason: "stop", codexTurnStatus: "completed" };
  assert.equal(vm.runInNewContext(expr, {
    promptError: "codex app-server error", promptErrorSource: "prompt", aborted: false,
    currentAttemptAssistant: undefined, sessionLastAssistant: previous,
    resolveFinalAssistantVisibleText: () => "A previous turn's answer", formatErrorMessage: String,
  }), false, "A previous turn's completed answer cannot recover this turn");
});
test("distinct final survives an earlier same-chat message tool progress report", async () => {
  assert.equal((await payloads()).at(0)?.text, final);
});
test("a longer final that quotes progress is not treated as a duplicate", async () => {
  const text = `${progress}\n\nUpdate: build completed, checks passed and checkpoint saved.`;
  assert.equal((await payloads({ payloads: [{ text }] }))[0]?.text, text);
});
test("identical already-delivered text is not sent twice, including short text", async () => {
  assert.equal((await payloads({ messagingToolSentTexts: [final] })).length, 0);
  assert.equal((await payloads({ payloads: [{ text: "Done" }], messagingToolSentTexts: ["Done"] })).length, 0);
});
test("new media survives a duplicate caption; sent media is removed", async () => {
  const replies = await payloads({
    payloads: [{ text: final, mediaUrl: "/tmp/new-report.pdf" }], messagingToolSentTexts: [final],
  });
  assert.equal(replies[0]?.mediaUrl, "/tmp/new-report.pdf");
  assert.ok(!replies[0]?.text);
  const sent = await payloads({
    payloads: [{ text: final, mediaUrl: "/tmp/already-sent.pdf" }],
    messagingToolSentMediaUrls: ["file:///tmp/already-sent.pdf"],
  });
  assert.equal(sent[0]?.text, final);
  assert.ok(!sent[0]?.mediaUrl);
});
test("silence, heartbeat and streaming controls are preserved", async () => {
  assert.equal((await payloads({ silentExpected: true })).length, 0);
  assert.equal((await payloads({ payloads: [{ text: "NO_REPLY" }] })).length, 0);
  assert.equal((await payloads({ payloads: [{ text: "HEARTBEAT_OK" }] })).length, 0);
  assert.equal((await payloads({ blockStreamingEnabled: true, blockReplyPipeline: {
    didStream: () => true, isAborted: () => false,
  } })).length, 0);
});
test("other channels and model providers retain their original suppression policy", async () => {
  assert.equal((await payloads({ modelProvider: "anthropic" })).length, 0);
  assert.equal((await payloads({
    messageProvider: "slack", originatingChannel: "slack",
    messagingToolSentTargets: [{ provider: "slack", to: "test-owner", accountId: "default" }],
  })).length, 0);
});
test("foreign recipients and accounts do not suppress an origin reply", async () => {
  for (const target of [
    { provider: "telegram", to: "someone-else", accountId: "default" },
    { provider: "telegram", to: "test-owner", accountId: "another-account" },
  ]) assert.equal((await payloads({ messagingToolSentTexts: [final], messagingToolSentTargets: [target] }))[0]?.text, final);
});
test("real Telegram formatter/delivery gets distinct final and yields a send receipt", async () => {
  const sends = [], logs = [];
  const result = await deliverReplies({
    replies: await payloads(), chatId: "test-owner", accountId: "default", textLimit: 4000,
    replyToMode: "off", bot: { api: { sendMessage: async (_to, text) => {
      sends.push(text); return { message_id: 123 };
    } } }, runtime: { log: (line) => logs.push(line), error() {} },
  });
  assert.equal(result.delivered, true);
  assert.equal(sends.length, 1);
  assert.ok(logs.some((line) => line.includes("sendMessage ok") && line.includes("message=123")));
});
test("Telegram rejection is never labeled delivered", async () => {
  let receipt = false;
  await assert.rejects(deliverReplies({
    replies: [{ text: final }], chatId: "test-owner", accountId: "default", textLimit: 4000,
    replyToMode: "off", bot: { api: { sendMessage: async () => { throw new Error("429 Too Many Requests"); } } },
    runtime: { log: (line) => { receipt ||= line.includes("sendMessage ok"); }, error() {} },
  }), /429/);
  assert.equal(receipt, false);
});
test("real caller supplies the model provider to scope the final-delivery repair", () => {
  assert.ok(/const payloadResult = await buildReplyPayloads\(\{\s*modelProvider: providerUsed,/.test(agent.source),
    "Missing modelProvider at the real caller");
});

function patchFixture(t, version = "2026.4.12") {
  const root = mkdtempSync(path.join(os.tmpdir(), "openclaw-delivery-regression-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const directory = path.join(root, "dist");
  mkdirSync(directory);
  writeFileSync(path.join(root, "package.json"), JSON.stringify({ version }));
  for (const file of [harness, agent, runner]) writeFileSync(path.join(directory, file.name), file.source);
  return directory;
}
function patchCommand(directory, args = []) {
  return spawnSync(process.execPath, [fileURLToPath(new URL("patch-codex-delivery.mjs", import.meta.url)), ...args], {
    env: { ...process.env, OPENCLAW_TEST_DIST: directory }, encoding: "utf8", timeout: 10000,
  });
}
test("patch reapplication is idempotent and check mode is read-only", (t) => {
  const directory = patchFixture(t);
  assert.equal(patchCommand(directory).status, 0);
  assert.equal(patchCommand(directory, ["--check"]).status, 0);
  for (const file of [harness, agent, runner]) assert.equal(readFileSync(path.join(directory, file.name), "utf8"), file.source);
});
test("unknown versions are rejected without modifying runtime files", (t) => {
  const directory = patchFixture(t, "2099.1.1");
  const result = patchCommand(directory);
  assert.notEqual(result.status, 0);
  assert.ok(result.stderr.includes("Unvalidated delivery runtime"));
  for (const file of [harness, agent, runner]) assert.equal(readFileSync(path.join(directory, file.name), "utf8"), file.source);
});
test("a marker with an incomplete patch fails validation", (t) => {
  const directory = patchFixture(t);
  const file = path.join(directory, harness.name);
  const broken = harness.source.replace("this.retryableErrorCount = 0;", "this.retryableErrorCount = 99;");
  assert.notEqual(broken, harness.source);
  writeFileSync(file, broken);
  const result = patchCommand(directory, ["--check"]);
  assert.notEqual(result.status, 0);
  assert.ok(result.stderr.includes("Incomplete codex-app-server-terminal-status-v3"));
  assert.equal(readFileSync(file, "utf8"), broken);
});
