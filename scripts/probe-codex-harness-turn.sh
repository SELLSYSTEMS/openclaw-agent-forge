#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_OPENCLAW_HOME_DIR="${OPENCLAW_HOME:-${ROOT}/.openclaw-home}"
SOURCE_CODEX_HOME_DIR="${CODEX_HOME:-${HOME}/.codex}"
OPENCLAW_BIN="${ROOT}/.openclaw/bin/openclaw"
SMOKE_TEXT="${OPENCLAW_CODEX_SMOKE_TEXT:-OPENCLAW-CODEX-HARNESS-SMOKE}"
SMOKE_TIMEOUT_SECONDS="${OPENCLAW_CODEX_SMOKE_TIMEOUT_SECONDS:-300}"
EXPECTED_THINKING_DEFAULT="${OPENCLAW_SMOKE_THINKING:-max}"
SMOKE_MODE="${OPENCLAW_CODEX_SMOKE_MODE:-agent}"
SOURCE_CONFIG_FILE="${SOURCE_OPENCLAW_HOME_DIR}/.openclaw/openclaw.json"

if [[ "${SMOKE_MODE}" != agent && "${SMOKE_MODE}" != infer ]]; then
  echo "OPENCLAW_CODEX_SMOKE_MODE must be agent or infer." >&2
  exit 1
fi

if [[ ! -x "${OPENCLAW_BIN}" ]]; then
  echo "OpenClaw binary is missing: ${OPENCLAW_BIN}" >&2
  exit 1
fi

if [[ ! -f "${SOURCE_CONFIG_FILE}" ]]; then
  echo "OpenClaw config is missing: ${SOURCE_CONFIG_FILE}" >&2
  exit 1
fi

MODEL_REF="${OPENCLAW_SMOKE_MODEL:-}"
if [[ -z "${MODEL_REF}" ]]; then
  MODEL_REF="$(
    env OPENCLAW_HOME="${SOURCE_OPENCLAW_HOME_DIR}" \
      "${OPENCLAW_BIN}" config get agents.defaults.model.primary 2>/dev/null || true
  )"
fi

if [[ "${MODEL_REF}" != codex/* ]]; then
  echo "Codex harness smoke requires a codex/<model> primary model, got ${MODEL_REF:-<unset>}" >&2
  exit 1
fi

ACTUAL_THINKING_DEFAULT="$(
  env OPENCLAW_HOME="${SOURCE_OPENCLAW_HOME_DIR}" \
    "${OPENCLAW_BIN}" config get agents.defaults.thinkingDefault 2>/dev/null || true
)"

if [[ "${ACTUAL_THINKING_DEFAULT}" != "${EXPECTED_THINKING_DEFAULT}" ]]; then
  echo "Codex harness smoke requires thinkingDefault=${EXPECTED_THINKING_DEFAULT}, got ${ACTUAL_THINKING_DEFAULT:-<unset>}" >&2
  exit 1
fi

MODEL_NAME="${MODEL_REF#codex/}"
TMP_OUTPUT="$(mktemp)"
SMOKE_OPENCLAW_HOME="$(mktemp -d "${ROOT}/.openclaw-home/harness-probe-XXXXXX")"
trap 'rm -f "${TMP_OUTPUT}"; rm -rf "${SMOKE_OPENCLAW_HOME}"' EXIT
mkdir -p "${SMOKE_OPENCLAW_HOME}/.openclaw"
cp --preserve=mode,timestamps "${SOURCE_CONFIG_FILE}" "${SMOKE_OPENCLAW_HOME}/.openclaw/openclaw.json"

# Native thread startup may persist workspace trust. Keep that write and probe
# history out of the shared Codex home while reusing the existing file login.
if [[ ! -f "${SOURCE_CODEX_HOME_DIR}/auth.json" ]]; then
  echo "Isolated harness probe requires the existing file-backed Codex login; no new login or API-key route will be created." >&2
  exit 1
fi
mkdir -p "${SMOKE_OPENCLAW_HOME}/codex"
cp --preserve=mode "${SOURCE_CODEX_HOME_DIR}/auth.json" "${SMOKE_OPENCLAW_HOME}/codex/auth.json"
chmod 600 "${SMOKE_OPENCLAW_HOME}/codex/auth.json"
if [[ -f "${SOURCE_CODEX_HOME_DIR}/config.toml" ]]; then
  cp --preserve=mode "${SOURCE_CODEX_HOME_DIR}/config.toml" "${SMOKE_OPENCLAW_HOME}/codex/config.toml"
  chmod 600 "${SMOKE_OPENCLAW_HOME}/codex/config.toml"
fi

# An explicit candidate must be testable before adding it to the live allowlist.
# A normal post-migration probe keeps the live model/allowlist contract unchanged.
if [[ -n "${OPENCLAW_SMOKE_MODEL:-}" ]]; then
  node - "${SMOKE_OPENCLAW_HOME}/.openclaw/openclaw.json" "${MODEL_REF}" <<'NODE'
const fs = require("fs");
const [file, model] = process.argv.slice(2);
const config = JSON.parse(fs.readFileSync(file, "utf8"));
const defaults = config.agents.defaults;
defaults.model = { ...defaults.model, primary: model };
defaults.models = { ...defaults.models, [model]: defaults.models?.[model] ?? {} };
fs.writeFileSync(file, JSON.stringify(config, null, 2) + "\n", { mode: 0o600 });
NODE
fi

if [[ "${SMOKE_MODE}" == agent ]]; then
  mkdir -p "${SMOKE_OPENCLAW_HOME}/workspace"
  node - "${SMOKE_OPENCLAW_HOME}" <<'NODE'
const fs = require("fs");
const path = require("path");
const home = process.argv[2];
const file = path.join(home, ".openclaw/openclaw.json");
const config = JSON.parse(fs.readFileSync(file, "utf8"));
config.agents.defaults.workspace = path.join(home, "workspace");
// No live agent directory, transcript, channel or project workspace in this test.
delete config.agents.list;
delete config.bindings;
config.channels = {};
fs.writeFileSync(file, JSON.stringify(config, null, 2) + "\n", { mode: 0o600 });
NODE
  SMOKE_COMMAND=(agent --local --session-id "codex-harness-probe-${RANDOM}-${RANDOM}"
    --message "This is an isolated runtime smoke test. Do not use tools or change files. Reply exactly: ${SMOKE_TEXT}"
    --thinking "${EXPECTED_THINKING_DEFAULT}" --json)
else
  SMOKE_COMMAND=(infer model run --model "${MODEL_REF}" --prompt "Reply exactly: ${SMOKE_TEXT}" --json)
fi

set +e
{
  timeout --kill-after=5s "${SMOKE_TIMEOUT_SECONDS}" \
    env OPENCLAW_HOME="${SMOKE_OPENCLAW_HOME}" \
    CODEX_HOME="${SMOKE_OPENCLAW_HOME}/codex" \
    OPENCLAW_AGENT_HARNESS_FALLBACK=none \
    "${OPENCLAW_BIN}" "${SMOKE_COMMAND[@]}" >"${TMP_OUTPUT}" 2>&1
  status=$?
} 2>/dev/null
set -e

if grep -F --quiet '"provider": "codex"' "${TMP_OUTPUT}" \
  && grep -F --quiet "\"model\": \"${MODEL_NAME}\"" "${TMP_OUTPUT}" \
  && grep -F --quiet "\"text\": \"${SMOKE_TEXT}\"" "${TMP_OUTPUT}"; then
  if [[ "${SMOKE_MODE}" == agent ]]; then
    node - "${SMOKE_OPENCLAW_HOME}" "${SMOKE_TEXT}" "${MODEL_NAME}" <<'NODE'
const fs = require("fs");
const path = require("path");
const [home, text, model] = process.argv.slice(2);
const sessions = path.join(home, ".openclaw/agents/main/sessions");
const files = fs.readdirSync(sessions).filter((name) => name.endsWith(".jsonl"));
const valid = files.some((name) => fs.readFileSync(path.join(sessions, name), "utf8").split("\n").filter(Boolean).some((line) => {
  const message = JSON.parse(line).message;
  return message?.role === "assistant" && message.provider === "codex" && message.model === model
    && message.stopReason === "stop" && message.codexTurnStatus === "completed"
    && !message.errorMessage && message.content?.some((part) => part.text === text);
}));
if (!valid) throw new Error("No successfully projected Codex final in the isolated transcript");
NODE
  fi
  echo "Codex harness smoke passed in isolated state: mode=${SMOKE_MODE} provider=codex model=${MODEL_NAME} thinking=${ACTUAL_THINKING_DEFAULT} produced the expected response."
  if [[ "${status}" == "124" || "${status}" == "137" ]]; then
    echo "Note: OpenClaw emitted the expected Codex result before the smoke timeout; timeout cleaned up the one-shot local app-server process." >&2
  elif [[ "${status}" != "0" ]]; then
    echo "Note: OpenClaw emitted the expected Codex result with non-zero wrapper status ${status}." >&2
  fi
  exit 0
fi

echo "Codex harness smoke failed for ${MODEL_REF}; output follows." >&2
cat "${TMP_OUTPUT}" >&2
exit 1
