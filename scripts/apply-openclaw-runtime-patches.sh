#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT}/.openclaw/lib/node_modules/openclaw/dist"
MARKER_V1="codex-app-server-recovery"
MARKER_V2="codex-app-server-recovery-v2"

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

if grep -q "${MARKER_V1}" "${RUNNER_FILE}" && grep -q "${MARKER_V2}" "${RUNNER_FILE}"; then
  node --check "${RUNNER_FILE}" >/dev/null
  echo "OpenClaw runtime patch already present: ${RUNNER_FILE}"
  exit 0
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
echo "Applied OpenClaw runtime patch: ${RUNNER_FILE}"
