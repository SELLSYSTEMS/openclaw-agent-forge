import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync, promises as fs } from "node:fs";
import { createHash } from "node:crypto";
import { spawnSync } from "node:child_process";
import os from "node:os";
import path from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import vm from "node:vm";
import { applyUnifiedDiff, botName, stockHash, managedHash, patchPath, hash } from "./ensure-telegram-outbox-base.mjs";

const dist = process.env.OPENCLAW_TEST_DIST ?? fileURLToPath(new URL(
  "../.openclaw/lib/node_modules/openclaw/dist/", import.meta.url,
));
const managed = readFileSync(path.join(dist, botName), "utf8");
assert.equal(hash(managed), managedHash, "Test the exact managed Telegram implementation");
const patch = readFileSync(patchPath, "utf8");
const reverse = patch.split("\n").map((line, i) => {
  if (i === 0) return `--- b/${botName}`;
  if (i === 1) return `+++ a/${botName}`;
  if (line.startsWith("@@ ")) return line.replace(/^@@ -(\d+,\d+) \+(\d+,\d+) @@/, "@@ -$2 +$1 @@");
  if (line.startsWith("+")) return `-${line.slice(1)}`;
  if (line.startsWith("-")) return `+${line.slice(1)}`;
  return line;
}).join("\n");
const stock = applyUnifiedDiff(managed, reverse);
assert.equal(hash(stock), stockHash, "Reconstructed fixture must match the official npm file");

function directory(t) {
  const root = mkdtempSync(path.join(os.tmpdir(), "openclaw-outbox-test-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  return root;
}
function fixture(t, source = stock, version = "2026.4.12") {
  const root = directory(t);
  const dist = path.join(root, "dist");
  mkdirSync(dist);
  writeFileSync(path.join(root, "package.json"), JSON.stringify({ version }));
  writeFileSync(path.join(dist, botName), source);
  return dist;
}
function command(directory, args = []) {
  return spawnSync(process.execPath, [fileURLToPath(new URL("ensure-telegram-outbox-base.mjs", import.meta.url)), ...args], {
    env: { ...process.env, OPENCLAW_TEST_DIST: directory }, encoding: "utf8", timeout: 10000,
  });
}

test("stock npm bot receives the exact existing outbox customization; checks and reapplication do not write", (t) => {
  const dist = fixture(t);
  const file = path.join(dist, botName);
  assert.notEqual(command(dist, ["--check"]).status, 0);
  assert.equal(readFileSync(file, "utf8"), stock);
  const result = command(dist);
  assert.equal(result.status, 0, result.stderr);
  assert.equal(readFileSync(file, "utf8"), managed);
  const modified = statSync(file).mtimeMs;
  assert.equal(command(dist).status, 0);
  assert.equal(command(dist, ["--check"]).status, 0);
  assert.equal(statSync(file).mtimeMs, modified);
});
test("unknown versions and modified bot files fail closed without writes", (t) => {
  for (const [source, version] of [[stock, "2099.1.1"], [`// local change\n${managed}`, "2026.4.12"]]) {
    const dist = fixture(t, source, version);
    assert.notEqual(command(dist).status, 0);
    assert.equal(readFileSync(path.join(dist, botName), "utf8"), source);
  }
});
test("unified patch validation rejects altered context and hunk counts", () => {
  assert.equal(hash(applyUnifiedDiff(stock, patch)), managedHash);
  assert.throws(() => applyUnifiedDiff(stock, patch.replace("const DRAFT_MIN_INITIAL_CHARS = 30;", "const DRAFT_MIN_INITIAL_CHARS = 31;")), /context mismatch/);
  assert.throws(() => applyUnifiedDiff(stock, patch.replace("-4319,6", "-4319,7")), /count mismatch/);
});

// Execute the real bundled outbox functions with private fixture storage and no network/timers.
function outbox(t) {
  const root = directory(t);
  const start = managed.indexOf("const TELEGRAM_DURABLE_OUTBOX_RELATIVE_DIR =");
  const end = managed.indexOf("async function resolveStickerVisionSupport", start);
  assert.ok(start >= 0 && end > start);
  const scheduled = [];
  const runtime = { log() {}, error() {} };
  const api = vm.runInNewContext(`${managed.slice(start, end)}\n({
    enqueue: enqueueTelegramDurableOutboxEntry,
    load: loadTelegramDurableOutboxEntries,
    drain: drainTelegramDurableOutbox,
    write: writeTelegramDurableOutboxFile,
    delay: computeTelegramDurableOutboxDelayMs
  })`, {
    fs, path, os, process, createHash,
    resolveStateDir: () => root,
    normalizeOptionalString: (value) => typeof value === "string" && value.trim() ? value.trim() : undefined,
    formatErrorMessage: String, danger: String,
    setTimeout: (_fn, delay) => { scheduled.push(delay); return { unref() {} }; }, clearTimeout() {},
    deliverReplies: () => { throw new Error("Unexpected network delivery"); },
  });
  return { ...api, runtime, scheduled };
}
const base = { accountId: "fixture-account", chatId: "fixture-owner", text: "Build finished; checkpoint saved.", reason: "final-after-delivery-failure" };
function enqueue(api, params = {}) { return api.enqueue({ ...base, runtime: api.runtime, ...params }); }
function drain(api, deliverReplies, params = {}) {
  return api.drain({ accountId: base.accountId, runtime: api.runtime, telegramDeps: { deliverReplies }, ...params });
}

test("generic failures are not queued or replayed as successful recovered answers", async (t) => {
  const api = outbox(t);
  assert.equal(await enqueue(api, { text: "Something went wrong while processing your request. Please try again." }), false);
  assert.equal(await enqueue(api, { reason: "processor-failure" }), false);
  assert.equal((await api.load(api.runtime)).length, 0);
  await api.write("stale.json", { ...base, reason: "processor-failure" });
  await drain(api, async () => { assert.fail("A stale generic failure must not be sent"); });
  assert.equal((await api.load(api.runtime)).length, 0);
});
test("a persisted real report is removed only after delivery is acknowledged", async (t) => {
  const api = outbox(t);
  assert.equal(await enqueue(api), true);
  assert.equal((await api.load(api.runtime))[0].entry.text, base.text);
  let sends = 0;
  await drain(api, async (params) => {
    sends++;
    assert.equal(params.chatId, base.chatId);
    assert.ok(params.replies[0].text.endsWith(base.text));
    assert.equal((await api.load(api.runtime)).length, 1, "Pending until transport acknowledges");
    return { delivered: true };
  });
  assert.equal(sends, 1);
  assert.equal((await api.load(api.runtime)).length, 0);
});
test("rejected and unacknowledged sends retain the report with bounded backoff", async (t) => {
  for (const rejection of [false, true]) {
    const api = outbox(t);
    await enqueue(api);
    await drain(api, async () => {
      if (rejection) throw new Error("429 Too Many Requests");
      return { delivered: false };
    });
    const entries = await api.load(api.runtime);
    assert.equal(entries.length, 1);
    assert.equal(entries[0].entry.text, base.text);
    assert.equal(entries[0].entry.attemptCount, 1);
    assert.ok(Date.parse(entries[0].entry.nextAttemptAt) > Date.now());
    assert.equal(api.scheduled[0], 30000);
    assert.equal(api.delay(100), 3600000);
  }
});
test("drains respect account, chat and due-time boundaries", async (t) => {
  const api = outbox(t);
  await enqueue(api);
  await enqueue(api, { accountId: "another-account" });
  await enqueue(api, { chatId: "another-chat" });
  await api.write("future.json", { ...base, nextAttemptAt: "2099-01-01T00:00:00Z" });
  let sends = 0;
  await drain(api, async () => { sends++; return { delivered: true }; }, { chatId: base.chatId });
  assert.equal(sends, 1);
  assert.equal((await api.load(api.runtime)).length, 3);
});
