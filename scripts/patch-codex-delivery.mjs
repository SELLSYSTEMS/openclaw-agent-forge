import { readFileSync, readdirSync, writeFileSync } from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../", import.meta.url));
const dist = process.env.OPENCLAW_TEST_DIST ?? path.join(root, ".openclaw/lib/node_modules/openclaw/dist");
const checkOnly = process.argv.includes("--check");
const version = JSON.parse(readFileSync(path.join(dist, "../package.json"), "utf8")).version;
if (version !== "2026.4.12") throw new Error(`Unvalidated delivery runtime ${version}; refusing to patch it`);
const staged = new Map();
function patch(prefix, signature, marker, edits) {
  const matches = readdirSync(dist).filter((name) => name.startsWith(prefix) && name.endsWith(".js"))
    .filter((name) => readFileSync(path.join(dist, name), "utf8").includes(signature));
  if (matches.length !== 1) throw new Error(`Expected exactly one ${prefix} runtime`);
  const file = path.join(dist, matches[0]);
  let source = readFileSync(file, "utf8");
  if (source.includes(marker)) {
    for (const [, replacement] of edits) {
      if (!source.includes(replacement)) throw new Error(`Incomplete ${marker}; refusing marker-only validation`);
    }
  } else {
    if (checkOnly) throw new Error(`Missing ${marker}; run scripts/apply-openclaw-runtime-patches.sh`);
    for (const [needle, replacement] of edits) {
      if (source.split(needle).length !== 2) throw new Error(`Changed ${marker} runtime shape: ${path.basename(file)}`);
      source = source.replace(needle, replacement);
    }
    source = `// ${marker}\n${source}`;
    staged.set(file, source);
  }
  const syntax = spawnSync(process.execPath, ["--input-type=module", "--check"], { input: source, encoding: "utf8" });
  if (syntax.status !== 0) throw new Error(`Invalid ${marker} syntax: ${syntax.stderr}`);
}

patch("harness-", "var CodexAppServerEventProjector = class", "codex-app-server-terminal-status-v3", [
  ["\t\tthis.promptErrorSource = null;\n\t\tthis.aborted = false;",
    "\t\tthis.promptErrorSource = null;\n\t\tthis.retryableErrorCount = 0;\n\t\tthis.aborted = false;"],
  [`\t\t\tcase "error":
\t\t\t\tthis.promptError = readString$1(params, "message") ?? "codex app-server error";
\t\t\t\tthis.promptErrorSource = "prompt";
\t\t\t\tbreak;`,
    `\t\t\tcase "error": {
\t\t\t\t// App-server v2 errors are turn-scoped and nested; willRetry is not terminal failure.
\t\t\t\tif (this.completedTurn || readString$1(params, "threadId") !== this.threadId || readString$1(params, "turnId") !== this.turnId) break;
\t\t\t\tif (params.willRetry === true) {
\t\t\t\t\tthis.retryableErrorCount += 1;
\t\t\t\t\tbreak;
\t\t\t\t}
\t\t\t\tthis.promptError = (isJsonObject(params.error) ? readString$1(params.error, "message") : void 0) ?? readString$1(params, "message") ?? "codex app-server error";
\t\t\t\tthis.promptErrorSource = "prompt";
\t\t\t\tbreak;
\t\t\t}`],
  [`\t\tif (!turn || turn.id !== this.turnId) return;
\t\tthis.completedTurn = turn;`,
    `\t\tif (!turn || turn.id !== this.turnId || this.completedTurn || !["completed", "failed", "interrupted"].includes(turn.status)) return;
\t\tthis.completedTurn = turn;
\t\tif (turn.status === "completed" && !this.aborted) {
\t\t\tthis.promptError = null;
\t\t\tthis.promptErrorSource = null;
\t\t}
\t\tlog.info(\`[codex-turn-status] status=\${turn.status} retryableErrors=\${this.retryableErrorCount} locallyAborted=\${this.aborted}\`);`],
  [`\t\t\tstopReason: this.aborted ? "aborted" : this.promptError ? "error" : "stop",`,
    `\t\t\tcodexTurnStatus: this.completedTurn?.status,
\t\t\tstopReason: this.aborted ? "aborted" : this.promptError ? "error" : "stop",`],
]);

patch("pi-embedded-runner-", "recoveredPostAnswerCodexAppServerError", "codex-terminal-recovery-guard", [
  ['if (recoveredText && /codex app-server (?:error|turn failed|attempt timed out)/i.test(promptErrorText)) {',
    'if (recoveredText && currentAttemptAssistant?.codexTurnStatus === "completed" && currentAttemptAssistant.stopReason === "stop" && /codex app-server (?:error|turn failed|attempt timed out)/i.test(promptErrorText)) {'],
  ['Boolean(promptError && promptErrorSource !== "compaction" && resolveFinalAssistantVisibleText(currentAttemptAssistant ?? sessionLastAssistant) && /codex app-server (?:error|turn failed|attempt timed out)/i.test(formatErrorMessage(promptError)))',
    'Boolean(promptError && !aborted && promptErrorSource !== "compaction" && currentAttemptAssistant?.codexTurnStatus === "completed" && currentAttemptAssistant.stopReason === "stop" && resolveFinalAssistantVisibleText(currentAttemptAssistant) && /codex app-server (?:error|turn failed|attempt timed out)/i.test(formatErrorMessage(promptError)))'],
]);

patch("agent-runner.runtime-", "async function buildReplyPayloads(params)", "codex-telegram-distinct-final", [
  ["\t\tconst payloadResult = await buildReplyPayloads({\n\t\t\tpayloads: payloadArray,",
    "\t\tconst payloadResult = await buildReplyPayloads({\n\t\t\tmodelProvider: providerUsed,\n\t\t\tpayloads: payloadArray,"],
  ["\tconst dedupeMessagingToolPayloads = suppressMessagingToolReplies || messagingToolSentTargets.length === 0;",
    `\tconst codexTelegramFinal = params.modelProvider === "codex" && resolveOriginMessageProvider({ originatingChannel: params.originatingChannel, provider: params.messageProvider }) === "telegram";
\tconst dedupeMessagingToolPayloads = suppressMessagingToolReplies || messagingToolSentTargets.length === 0;`],
  ["\tconst dedupedPayloads = dedupeMessagingToolPayloads ? (dedupeRuntime ?? await loadReplyPayloadsDedupeRuntime()).filterMessagingToolDuplicates({",
    `\t// Exact text dedupe only: a final report may quote an earlier progress message.
\tconst normalizeCodexSentText = (text) => typeof text === "string" ? text.trim().replace(/\\s+/g, " ") : "";
\tconst codexSentTexts = new Set(messagingToolSentTexts.map(normalizeCodexSentText).filter(Boolean));
\tconst dedupedPayloads = codexTelegramFinal && dedupeMessagingToolPayloads ? silentFilteredPayloads.map((payload) => codexSentTexts.has(normalizeCodexSentText(payload.text)) ? { ...payload, text: void 0 } : payload) : dedupeMessagingToolPayloads ? (dedupeRuntime ?? await loadReplyPayloadsDedupeRuntime()).filterMessagingToolDuplicates({`],
  [`\treturn {
\t\treplyPayloads: suppressMessagingToolReplies ? [] : filteredPayloads,
\t\tdidLogHeartbeatStrip
\t};`,
    `\tconst replyPayloads = suppressMessagingToolReplies && !codexTelegramFinal ? [] : codexTelegramFinal ? filteredPayloads.filter(isRenderablePayload) : filteredPayloads;
\tif (codexTelegramFinal) defaultRuntime.log?.(\`[codex-telegram-final] stage=prepared inputPayloads=\${params.payloads.length} outputPayloads=\${replyPayloads.length} priorTargetMatch=\${suppressMessagingToolReplies}\`);
\treturn {
\t\treplyPayloads,
\t\tdidLogHeartbeatStrip
\t};`],
]);

// Validate every target before writing any of these runtime changes.
for (const [file, source] of staged) writeFileSync(file, source);
console.log(`Codex terminal-status and Telegram final-delivery contract ${checkOnly ? "verified" : "applied"}; files changed=${staged.size}`);
