#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT}/.openclaw/lib/node_modules/openclaw/dist"
MARKER="codex-app-server-recovery"

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

if grep -q "${MARKER}" "${RUNNER_FILE}"; then
  node --check "${RUNNER_FILE}" >/dev/null
  echo "OpenClaw runtime patch already present: ${RUNNER_FILE}"
  exit 0
fi

node - "${RUNNER_FILE}" <<'NODE'
const fs = require("fs");

const file = process.argv[2];
const source = fs.readFileSync(file, "utf8");
const marker = "codex-app-server-recovery";

if (source.includes(marker)) {
  process.exit(0);
}

const needle = `				currentAttemptAssistant = findCurrentAttemptAssistantMessage({
					messagesSnapshot,
					prePromptMessageCount
				});
				attemptUsage = getUsageTotals();`;

const replacement = `				currentAttemptAssistant = findCurrentAttemptAssistantMessage({
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

if (!source.includes(needle)) {
  console.error("OpenClaw runner shape changed; cannot apply Codex app-server recovery patch safely.");
  console.error(`File: ${file}`);
  process.exit(1);
}

fs.writeFileSync(file, source.replace(needle, replacement));
NODE

node --check "${RUNNER_FILE}" >/dev/null
echo "Applied OpenClaw runtime patch: ${RUNNER_FILE}"
