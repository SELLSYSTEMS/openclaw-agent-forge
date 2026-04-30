#!/usr/bin/env python3
import argparse
import glob
import json
import os
import sys
from typing import Any

DEFAULT_STATE_FILE = "/opt/claude-vnc-terminal/data/terminal-state.json"


def load_terminals(state_file: str) -> list[dict[str, Any]]:
    try:
        with open(state_file, "r", encoding="utf-8") as f:
            data = json.load(f)
    except FileNotFoundError:
        return []
    except json.JSONDecodeError as exc:
        raise SystemExit(f"failed to parse {state_file}: {exc}")
    terminals = data.get("terminals")
    if not isinstance(terminals, list):
        return []
    return [t for t in terminals if isinstance(t, dict)]


def resolve_target_cwd(args: argparse.Namespace) -> tuple[str, dict[str, Any] | None]:
    if args.cwd:
        return args.cwd, None

    terminals = load_terminals(args.state_file)
    matches = [t for t in terminals if t.get("name") == args.tab_name]
    if not matches:
        raise SystemExit(f"tab not found in {args.state_file}: {args.tab_name}")

    cwds = sorted({t.get("cwd") for t in matches if isinstance(t.get("cwd"), str) and t.get("cwd")})
    if not cwds:
        raise SystemExit(f"tab found but has no cwd: {args.tab_name}")
    if len(cwds) > 1:
        raise SystemExit(
            f"tab name is ambiguous across multiple cwd values: {args.tab_name} -> {', '.join(cwds)}"
        )

    target_cwd = cwds[0]
    terminal = next((t for t in matches if t.get("cwd") == target_cwd), matches[0])
    return target_cwd, terminal


def scan_ptys(target_cwd: str) -> list[dict[str, Any]]:
    by_tty: dict[str, dict[str, Any]] = {}
    for proc_path in glob.glob("/proc/[0-9]*"):
        pid = os.path.basename(proc_path)
        try:
            cwd = os.readlink(f"{proc_path}/cwd")
            if cwd != target_cwd:
                continue
            tty = os.readlink(f"{proc_path}/fd/0")
            if not tty.startswith("/dev/pts/"):
                continue
            with open(f"{proc_path}/cmdline", "rb") as f:
                cmd = f.read().replace(b"\x00", b" ").decode("utf-8", "ignore").strip()
        except Exception:
            continue

        entry = by_tty.setdefault(
            tty,
            {
                "tty": tty,
                "cwd": target_cwd,
                "pids": [],
                "cmds": [],
            },
        )
        entry["pids"].append(int(pid))
        if cmd and cmd not in entry["cmds"]:
            entry["cmds"].append(cmd)

    return sorted(by_tty.values(), key=lambda item: item["tty"])


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Resolve the live PTY for an existing agent terminal from a tab name or cwd."
    )
    target = parser.add_mutually_exclusive_group(required=True)
    target.add_argument("--tab-name", help="Tab name from terminal-state.json")
    target.add_argument("--cwd", help="Exact working directory of the target terminal")
    parser.add_argument("--state-file", default=DEFAULT_STATE_FILE, help="Path to terminal-state.json")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of shell-style output")
    args = parser.parse_args()

    target_cwd, terminal = resolve_target_cwd(args)
    candidates = scan_ptys(target_cwd)
    if not candidates:
        raise SystemExit(f"no /dev/pts/* candidates found for cwd={target_cwd}")
    if len(candidates) > 1:
        payload = {
            "tab_name": args.tab_name,
            "cwd": target_cwd,
            "terminal": terminal,
            "candidates": candidates,
        }
        if args.json:
            print(json.dumps(payload, indent=2, sort_keys=True))
        else:
            print(f"ambiguous PTY candidates for cwd={target_cwd}", file=sys.stderr)
            for item in candidates:
                print(f"{item['tty']} pids={item['pids']} cmds={item['cmds']}", file=sys.stderr)
        raise SystemExit(2)

    result = {
        "tab_name": args.tab_name,
        "cwd": target_cwd,
        "terminal": terminal,
        "tty": candidates[0]["tty"],
        "pids": candidates[0]["pids"],
        "cmds": candidates[0]["cmds"],
    }
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(f"TTY={result['tty']} CWD={result['cwd']} PIDS={','.join(map(str, result['pids']))}")


if __name__ == "__main__":
    main()
