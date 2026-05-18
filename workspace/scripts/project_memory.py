#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path


WORKSPACE = Path(__file__).resolve().parent.parent
PROJECTS_DIR = WORKSPACE / "memory" / "projects"
REGISTRY_PATH = PROJECTS_DIR / "registry.json"
INDEX_PATH = PROJECTS_DIR / "_index.md"
TEMPLATE_PATH = PROJECTS_DIR / "_template.md"


def load_registry() -> dict:
    if REGISTRY_PATH.exists():
        return json.loads(REGISTRY_PATH.read_text())
    return {"projects": []}


def save_registry(registry: dict) -> None:
    REGISTRY_PATH.write_text(json.dumps(registry, indent=2, ensure_ascii=False) + "\n")


def render_index(registry: dict) -> str:
    projects = sorted(registry.get("projects", []), key=lambda x: x["slug"])
    lines = [
        "# Project memory index",
        "",
        "Canonical per-project memory lives here.",
        "",
        "## Active projects",
        "",
    ]
    if not projects:
        lines.append("- _none yet_")
    for project in projects:
        lines.extend(
            [
                f"- `{project['slug']}`",
                f"  - Name: {project['name']}",
                f"  - Type: {project.get('type', '')}",
                f"  - Root: `{project.get('root', '')}`",
                f"  - Canonical dossier: `{project.get('canonicalDossier', '')}`",
                f"  - Status: {project.get('status', '')}",
            ]
        )
    lines.extend(
        [
            "",
            "## Rules",
            "",
            "- One dossier per real project",
            "- Keep stable truth in the dossier",
            "- Keep day-by-day events in `memory/YYYY-MM-DD.md`",
            "- Update the registry when a new project is created",
        ]
    )
    return "\n".join(lines) + "\n"


def rebuild_index() -> None:
    registry = load_registry()
    INDEX_PATH.write_text(render_index(registry))


def init_project(args: argparse.Namespace) -> None:
    PROJECTS_DIR.mkdir(parents=True, exist_ok=True)
    registry = load_registry()
    dossier_rel = f"memory/projects/{args.slug}.md"
    project = {
        "slug": args.slug,
        "name": args.name,
        "type": args.type,
        "status": args.status,
        "root": args.root,
        "unixUser": args.unix_user or "",
        "canonicalDossier": dossier_rel,
        "primaryDocs": args.doc or [],
        "tags": args.tag or [],
        "startedAs": args.started_as or "",
        "notes": args.notes or "",
    }

    projects = registry.setdefault("projects", [])
    existing = next((p for p in projects if p["slug"] == args.slug), None)
    if existing:
        if not args.update:
            raise SystemExit(f"Project slug '{args.slug}' already exists. Use --update.")
        existing.update(project)
    else:
        projects.append(project)

    save_registry(registry)
    rebuild_index()

    dossier_path = WORKSPACE / dossier_rel
    if dossier_path.exists() and not args.overwrite_dossier:
        return

    template = TEMPLATE_PATH.read_text()
    rendered = (
        template.replace("{{NAME}}", args.name)
        .replace("{{TYPE}}", args.type)
        .replace("{{ROOT}}", args.root)
        .replace("{{UNIX_USER}}", args.unix_user or "")
        .replace("{{STATUS}}", args.status)
    )
    dossier_path.write_text(rendered)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Project memory helper")
    subparsers = parser.add_subparsers(dest="command", required=True)

    init_parser = subparsers.add_parser("init", help="create or update a project memory entry")
    init_parser.add_argument("--slug", required=True)
    init_parser.add_argument("--name", required=True)
    init_parser.add_argument("--type", required=True)
    init_parser.add_argument("--root", required=True)
    init_parser.add_argument("--status", default="active")
    init_parser.add_argument("--unix-user")
    init_parser.add_argument("--started-as")
    init_parser.add_argument("--notes")
    init_parser.add_argument("--tag", action="append")
    init_parser.add_argument("--doc", action="append")
    init_parser.add_argument("--update", action="store_true")
    init_parser.add_argument("--overwrite-dossier", action="store_true")
    init_parser.set_defaults(func=init_project)

    rebuild_parser = subparsers.add_parser("rebuild-index", help="rebuild the human-readable index")
    rebuild_parser.set_defaults(func=lambda _: rebuild_index())

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
