import assert from "node:assert/strict";
import test from "node:test";
import { summarizeTranscript } from "./inspect-last-turn.mjs";

const message = (role, extra = {}) => JSON.stringify({
  type: "message", timestamp: "2026-01-01T00:00:00Z", message: { role, ...extra },
});
const quota = message("assistant", {
  stopReason: "error", errorMessage: "You've hit your usage limit. PRIVATE_TEST_TEXT",
});

test("usage-limit failure is detected without printing private text", async () => {
  const result = await summarizeTranscript([message("user"), quota]);
  assert.equal(result.state, "failed");
  assert.equal(result.error_class, "provider_usage_limit");
  assert.ok(!JSON.stringify(result).includes("PRIVATE_TEST_TEXT"));
});

test("user quoting an error is not a provider failure", async () => {
  const result = await summarizeTranscript([message("user", { content: "You've hit your usage limit" })]);
  assert.equal(result.state, "awaiting_or_interrupted");
  assert.equal(result.error_class, null);
});

test("later completed response supersedes a historical quota failure", async () => {
  const result = await summarizeTranscript([quota, message("user"), message("assistant", { stopReason: "stop" })]);
  assert.equal(result.state, "completed");
  assert.equal(result.error_class, null);
});

test("incomplete tool turn never claims that a live worker exists", async () => {
  const result = await summarizeTranscript([message("user"), message("assistant", { stopReason: "toolUse" })]);
  assert.equal(result.state, "awaiting_or_interrupted");
});

test("other runtime errors remain separate from quota", async () => {
  const result = await summarizeTranscript([message("assistant", { stopReason: "error", errorMessage: "Connection closed" })]);
  assert.equal(result.error_class, "runtime_error");
});

test("corrupt JSONL fails closed instead of claiming a completed turn", async () => {
  const result = await summarizeTranscript([message("assistant", { stopReason: "stop" }), "{broken"]);
  assert.equal(result.state, "unknown_malformed_transcript");
  assert.equal(result.malformed_records, 1);
});
