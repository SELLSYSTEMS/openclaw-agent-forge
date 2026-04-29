#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_FILE="/opt/claude-vnc-terminal/data/terminal-state.json"
MODE=""
TARGET=""
APPEND_NEWLINE="1"

usage() {
  cat <<'EOF'
Usage:
  scripts/write-live-terminal.sh --tab-name <name> -- <text>
  scripts/write-live-terminal.sh --cwd <path> -- <text>

Options:
  --tab-name <name>   Resolve the target cwd from terminal-state.json
  --cwd <path>        Target a live terminal by exact cwd
  --state-file <path> Override terminal-state.json path
  --no-newline        Do not append a trailing newline
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tab-name)
      MODE="--tab-name"
      TARGET="${2:-}"
      shift 2
      ;;
    --cwd)
      MODE="--cwd"
      TARGET="${2:-}"
      shift 2
      ;;
    --state-file)
      STATE_FILE="${2:-}"
      shift 2
      ;;
    --no-newline)
      APPEND_NEWLINE="0"
      shift
      ;;
    --)
      shift
      break
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${MODE}" || -z "${TARGET}" || $# -lt 1 ]]; then
  usage >&2
  exit 2
fi

TEXT="$*"
JSON="$("${ROOT}/scripts/find-live-terminal.py" "${MODE}" "${TARGET}" --state-file "${STATE_FILE}" --json)"
TTY="$(printf '%s\n' "${JSON}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["tty"])')"

python3 - "${TTY}" "${TEXT}" "${APPEND_NEWLINE}" <<'PY'
import sys

tty = sys.argv[1]
text = sys.argv[2]
append_newline = sys.argv[3] == "1"

with open(tty, "w", buffering=1) as f:
    f.write(text + ("\n" if append_newline else ""))
PY

echo "WROTE tty=${TTY}"
