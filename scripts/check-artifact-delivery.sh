#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: check-artifact-delivery.sh --target <target> <file> [file...]

Targets:
  telegram-bot   Check Telegram Bot API direct document upload safety.
  public-link    Report required public URL verification before sharing.
  github-release Report required GitHub Release limit/permission verification.
  node-red       Report required Node-RED flow and payload verification.
  local-path     Confirm the file exists for server-local handoff.

This helper is conservative. For systems with changing or config-specific limits,
it reports the required live verification instead of pretending a stale global
limit is always correct.
USAGE
}

TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      if [[ $# -lt 2 ]]; then
        usage >&2
        exit 2
      fi
      TARGET="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    --*)
      echo "unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

if [[ -z "$TARGET" || $# -lt 1 ]]; then
  usage >&2
  exit 2
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
EXIT_CODE=0

for path in "$@"; do
  if [[ ! -f "$path" ]]; then
    printf 'missing\t%s\t0\t%s\n' "$TARGET" "$path"
    EXIT_CODE=1
    continue
  fi

  size="$(stat -c '%s' "$path")"

  case "$TARGET" in
    telegram|telegram-bot|telegram-media)
      if ! "$SCRIPT_DIR/check-telegram-media-size.sh" "$path"; then
        EXIT_CODE=1
      fi
      ;;
    public-link|nginx|download-link)
      printf 'verify_public_url\t%s\t%s\t%s\n' "$TARGET" "$size" "$path"
      ;;
    github|github-release|release)
      printf 'check_live_github_limits\t%s\t%s\t%s\n' "$TARGET" "$size" "$path"
      ;;
    node-red|nodered)
      printf 'check_live_node_red_limits\t%s\t%s\t%s\n' "$TARGET" "$size" "$path"
      ;;
    local|local-path|filesystem)
      printf 'ok\t%s\t%s\t%s\n' "$TARGET" "$size" "$path"
      ;;
    *)
      printf 'unknown_target\t%s\t%s\t%s\n' "$TARGET" "$size" "$path"
      EXIT_CODE=2
      ;;
  esac
done

exit "$EXIT_CODE"
