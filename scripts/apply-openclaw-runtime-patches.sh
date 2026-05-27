#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT}/.openclaw/lib/node_modules/openclaw/dist"
MARKER_V1="codex-app-server-recovery"
MARKER_V2="codex-app-server-recovery-v2"
MARKER_TG_OUTBOX_V1="telegram-durable-outbox-skip-generic-failures"

if [[ ! -d "${DIST_DIR}" ]]; then
  echo "OpenClaw dist directory not found: ${DIST_DIR}" >&2
  echo "Run scripts/bootstrap-openclaw.sh first." >&2
  exit 1
fi

RUNNER_FILE="$(find "${DIST_DIR}" -maxdepth 1 -name 'pi-embedded-runner-*.js' -print -quit)"
if [[ -z "${RUNNER_FILE}" || ! -f "${RUNNER_FILE}" ]]; then
  echo "Unable to find OpenClaw pi embedded runner in ${DIST_DIR}" >&2
  exit 1
fi

node - "${RUNNER_FILE}" <<'NODE'
const fs = require("fs");

const file = process.argv[2];
let source = fs.readFileSync(file, "utf8");
const markerV1 = "codex-app-server-recovery";
const markerV2 = "codex-app-server-recovery-v2";

const needleV1 = `				currentAttemptAssistant = findCurrentAttemptAssistantMessage({
					messagesSnapshot,
					prePromptMessageCount
				});
				attemptUsage = getUsageTotals();`;

const replacementV1 = `				currentAttemptAssistant = findCurrentAttemptAssistantMessage({
					messagesSnapshot,
					prePromptMessageCount
				});
				if (promptError && promptErrorSource === "prompt") {
					const recoveredAssistant = currentAttemptAssistant ?? lastAssistant;
					const recoveredText = recoveredAssistant ? extractAssistantVisibleText(recoveredAssistant).trim() : "";
					const promptErrorText = formatErrorMessage(promptError);
					if (recoveredText && /codex app-server (?:error|turn failed|attempt timed out)/i.test(promptErrorText)) {
						log$3.warn(\`[codex-app-server-recovery] preserving assistant reply after post-answer app-server error: runId=\${params.runId} sessionId=\${params.sessionId} error=\${sanitizeForLog(promptErrorText)}\`);
						promptError = null;
						promptErrorSource = null;
						for (const assistant of [currentAttemptAssistant, lastAssistant]) if (assistant && assistant.stopReason === "error") {
							assistant.stopReason = "stop";
							delete assistant.errorMessage;
						}
					}
				}
				attemptUsage = getUsageTotals();`;

if (!source.includes(markerV1)) {
  if (!source.includes(needleV1)) {
    console.error("OpenClaw runner shape changed; cannot apply Codex app-server recovery patch v1 safely.");
    console.error(`File: ${file}`);
    process.exit(1);
  }
  source = source.replace(needleV1, replacementV1);
}

const needleV2 = `					const activeErrorContext = resolveActiveErrorContext({
						provider,
						model: modelId,
						assistant: currentAttemptAssistant ?? sessionLastAssistant
					});
					const resolveReplayInvalidForAttempt = (incompleteTurnText) => accumulatedReplayState.replayInvalid || resolveReplayInvalidFlag({`;

const replacementV2 = `					const activeErrorContext = resolveActiveErrorContext({
						provider,
						model: modelId,
						assistant: currentAttemptAssistant ?? sessionLastAssistant
					});
					const recoveredPostAnswerCodexAppServerError = Boolean(promptError && promptErrorSource !== "compaction" && resolveFinalAssistantVisibleText(currentAttemptAssistant ?? sessionLastAssistant) && /codex app-server (?:error|turn failed|attempt timed out)/i.test(formatErrorMessage(promptError)));
					if (recoveredPostAnswerCodexAppServerError) {
						log$3.warn(\`[codex-app-server-recovery-v2] preserving assistant reply after outer post-answer app-server error: runId=\${params.runId} sessionId=\${params.sessionId} error=\${sanitizeForLog(formatErrorMessage(promptError))}\`);
						for (const assistant of [currentAttemptAssistant, sessionLastAssistant]) if (assistant && assistant.stopReason === "error") {
							assistant.stopReason = "stop";
							delete assistant.errorMessage;
						}
					}
					const resolveReplayInvalidForAttempt = (incompleteTurnText) => accumulatedReplayState.replayInvalid || resolveReplayInvalidFlag({`;

const needleV2Guard = `					if (promptError && !aborted && promptErrorSource !== "compaction") {`;
const replacementV2Guard = `					if (promptError && !recoveredPostAnswerCodexAppServerError && !aborted && promptErrorSource !== "compaction") {`;

if (!source.includes(markerV2)) {
  if (!source.includes(needleV2) || !source.includes(needleV2Guard)) {
    console.error("OpenClaw runner shape changed; cannot apply Codex app-server recovery patch v2 safely.");
    console.error(`File: ${file}`);
    process.exit(1);
  }
  source = source.replace(needleV2, replacementV2);
  source = source.replace(needleV2Guard, replacementV2Guard);
}

fs.writeFileSync(file, source);
NODE

node --check "${RUNNER_FILE}" >/dev/null

BOT_FILE="$(grep -l 'TELEGRAM_DURABLE_OUTBOX_RECOVERY_PREFIX' "${DIST_DIR}"/bot-*.js 2>/dev/null | head -n 1 || true)"
if [[ -z "${BOT_FILE}" || ! -f "${BOT_FILE}" ]]; then
  echo "Unable to find OpenClaw Telegram bot runtime in ${DIST_DIR}" >&2
  exit 1
fi

node - "${BOT_FILE}" "${MARKER_TG_OUTBOX_V1}" <<'NODE'
const fs = require("fs");

const file = process.argv[2];
const marker = process.argv[3];
let source = fs.readFileSync(file, "utf8");

if (!source.includes(marker)) {
  const constantsNeedle = `const TELEGRAM_DURABLE_OUTBOX_RECOVERY_PREFIX = "⚠️ Recovered after an earlier Telegram delivery failure.\\n\\n";`;
  const constantsReplacement = `${constantsNeedle}
const TELEGRAM_DURABLE_OUTBOX_GENERIC_FAILURE_TEXTS = new Set([
	"Something went wrong while processing your request. Please try again.",
	"⚠️ Something went wrong while processing your request. Please try again, or use /new to start a fresh session."
]);
function isTelegramDurableOutboxGenericFailureText(text) {
	const normalized = typeof text === "string" ? text.trim() : "";
	if (!normalized) return false;
	if (TELEGRAM_DURABLE_OUTBOX_GENERIC_FAILURE_TEXTS.has(normalized)) return true;
	return /^⚠️ Recovered after an earlier Telegram delivery failure\\.\\s+Something went wrong while processing your request\\. Please try again\\.?$/s.test(normalized);
}
function shouldSkipTelegramDurableOutboxEntry(params) {
	if (isTelegramDurableOutboxGenericFailureText(params?.text)) return "${marker}";
	const reason = typeof params?.reason === "string" ? params.reason : "";
	if (reason === "processor-failure") return "${marker}";
	if (reason === "fallback-after-dispatch-error") return "${marker}";
	if (reason === "fallback-after-delivery-failure") return "${marker}";
	return "";
}`;

  const enqueueNeedle = `	const text = typeof params.text === "string" ? params.text.trim() : "";
	if (!text) return false;`;
  const enqueueReplacement = `${enqueueNeedle}
	const skipReason = shouldSkipTelegramDurableOutboxEntry({ text, reason: params.reason });
	if (skipReason) {
		params.runtime.log?.(\`telegram durable outbox skipped non-actionable generic failure chat=\${String(params.chatId)} reason=\${params.reason ?? "unknown"} marker=\${skipReason}\`);
		return false;
	}`;

  const drainNeedle = `			const recoveryText = buildTelegramDurableOutboxRecoveryText(item.entry.text);
			if (!recoveryText) {
				await removeTelegramDurableOutboxEntry(item);
				continue;
			}`;
  const drainReplacement = `			const staleSkipReason = shouldSkipTelegramDurableOutboxEntry({ text: item.entry.text, reason: item.entry.reason });
			if (staleSkipReason) {
				params.runtime.log?.(\`telegram durable outbox dropped non-actionable generic failure chat=\${item.entry?.chatId ?? "unknown"} file=\${item.fileName} reason=\${item.entry?.reason ?? "unknown"} marker=\${staleSkipReason}\`);
				await removeTelegramDurableOutboxEntry(item);
				continue;
			}
			const recoveryText = buildTelegramDurableOutboxRecoveryText(item.entry.text);
			if (!recoveryText) {
				await removeTelegramDurableOutboxEntry(item);
				continue;
			}`;

  for (const [needle, replacement, label] of [
    [constantsNeedle, constantsReplacement, "telegram durable outbox constants"],
    [enqueueNeedle, enqueueReplacement, "telegram durable outbox enqueue guard"],
    [drainNeedle, drainReplacement, "telegram durable outbox drain guard"]
  ]) {
    if (!source.includes(needle)) {
      console.error(`OpenClaw bot runtime shape changed; cannot apply ${label} patch safely.`);
      console.error(`File: ${file}`);
      process.exit(1);
    }
    source = source.replace(needle, replacement);
  }

  fs.writeFileSync(file, source);
}
NODE

node --check "${BOT_FILE}" >/dev/null
echo "OpenClaw runtime patches present: ${RUNNER_FILE}"
echo "OpenClaw Telegram durable outbox patch present: ${BOT_FILE}"
