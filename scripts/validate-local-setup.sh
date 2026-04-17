#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCHER="${ROOT}/bin/openclaw-local"
EXPECTED_WORKSPACE="${ROOT}/workspace"
EXPECTED_MODEL="codex-cli/gpt-5.4"
EXPECTED_GATEWAY_MODE="local"
EXPECTED_GATEWAY_BIND="loopback"

"${LAUNCHER}" --version
env OPENCLAW_HOME="${ROOT}/.openclaw-home" "${ROOT}/.openclaw/bin/openclaw" config validate

actual_workspace="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.workspace
)"

if [[ "${actual_workspace}" != "${EXPECTED_WORKSPACE}" ]]; then
  echo "Workspace mismatch: expected ${EXPECTED_WORKSPACE}, got ${actual_workspace}" >&2
  exit 1
fi

actual_model="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get agents.defaults.model.primary
)"

if [[ "${actual_model}" != "${EXPECTED_MODEL}" ]]; then
  echo "Model mismatch: expected ${EXPECTED_MODEL}, got ${actual_model}" >&2
  exit 1
fi

actual_gateway_mode="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get gateway.mode
)"

if [[ "${actual_gateway_mode}" != "${EXPECTED_GATEWAY_MODE}" ]]; then
  echo "Gateway mode mismatch: expected ${EXPECTED_GATEWAY_MODE}, got ${actual_gateway_mode}" >&2
  exit 1
fi

actual_gateway_bind="$(
  env OPENCLAW_HOME="${ROOT}/.openclaw-home" \
    "${ROOT}/.openclaw/bin/openclaw" config get gateway.bind
)"

if [[ "${actual_gateway_bind}" != "${EXPECTED_GATEWAY_BIND}" ]]; then
  echo "Gateway bind mismatch: expected ${EXPECTED_GATEWAY_BIND}, got ${actual_gateway_bind}" >&2
  exit 1
fi

codex login status >/dev/null

echo "Local setup validated."
