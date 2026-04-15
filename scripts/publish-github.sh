#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OWNER="${1:-${GITHUB_OWNER:-ryuriymega}}"
REPO_NAME="${2:-openclaw-agent-forge}"
VISIBILITY="${3:-public}"
DESCRIPTION="Codex-built bootstrap for a live OpenClaw AI server and multi-agent workspace."
TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"

if [[ -z "${TOKEN}" ]]; then
  echo "Set GITHUB_TOKEN or GH_TOKEN before publishing." >&2
  exit 1
fi

if [[ "${VISIBILITY}" != "public" && "${VISIBILITY}" != "private" ]]; then
  echo "Visibility must be public or private." >&2
  exit 1
fi

private_flag="false"
if [[ "${VISIBILITY}" == "private" ]]; then
  private_flag="true"
fi

api_url="https://api.github.com/repos/${OWNER}/${REPO_NAME}"
create_payload="$(printf '{"name":"%s","description":"%s","private":%s}' "${REPO_NAME}" "${DESCRIPTION}" "${private_flag}")"

repo_status="$(
  curl -sS -o /tmp/openclaw-agent-forge-repo-check.json -w '%{http_code}' \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${TOKEN}" \
    "${api_url}"
)"

if [[ "${repo_status}" == "404" ]]; then
  create_status="$(
    curl -sS -o /tmp/openclaw-agent-forge-repo-create.json -w '%{http_code}' \
      -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${TOKEN}" \
      https://api.github.com/user/repos \
      -d "${create_payload}"
  )"

  if [[ "${create_status}" != "201" ]]; then
    echo "GitHub repo creation failed with HTTP ${create_status}." >&2
    cat /tmp/openclaw-agent-forge-repo-create.json >&2
    exit 1
  fi
elif [[ "${repo_status}" != "200" ]]; then
  echo "GitHub repo lookup failed with HTTP ${repo_status}." >&2
  cat /tmp/openclaw-agent-forge-repo-check.json >&2
  exit 1
fi

remote_url="https://github.com/${OWNER}/${REPO_NAME}.git"

if git -C "${ROOT}" remote get-url origin >/dev/null 2>&1; then
  git -C "${ROOT}" remote set-url origin "${remote_url}"
else
  git -C "${ROOT}" remote add origin "${remote_url}"
fi

git -C "${ROOT}" push -u "https://x-access-token:${TOKEN}@github.com/${OWNER}/${REPO_NAME}.git" main

echo "Published to ${remote_url}"
