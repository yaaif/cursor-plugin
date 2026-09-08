#!/usr/bin/env python3
"""Inventory checks for the YAAIF Cursor plugin (commands + preview/apply contract)."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

PLUGIN_VERSION = "1.3.2"

EXPECTED_SKILLS = (
    "yaaif-auth",
    "yaaif-create-ambient",
    "yaaif-create-mcp",
    "yaaif-create-skill",
    "yaaif-doctor",
    "yaaif-ops-support",
    "yaaif-plan-usecase",
    "yaaif-platform-tools",
    "yaaif-scenario",
)

EXPECTED_COMMANDS = (
    "yaaif-doctor",
    "yaaif-login",
    "yaaif-new-mcp",
    "yaaif-new-skill",
    "yaaif-new-workflow",
    "yaaif-ops",
    "yaaif-plan",
    "yaaif-platform-tools",
    "yaaif-scenario",
    "yaaif-sync-scenario",
)

PREVIEW_APPLY_COMMANDS = ("yaaif-scenario", "yaaif-sync-scenario")


def _load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def check_inventory(root: Path) -> list[str]:
    errors: list[str] = []
    plugin_path = root / ".cursor-plugin" / "plugin.json"
    if not plugin_path.is_file():
        return [f"missing {plugin_path}"]
    plugin = _load_json(plugin_path)
    if plugin.get("version") != PLUGIN_VERSION:
        errors.append(f"plugin.json version {plugin.get('version')!r} != {PLUGIN_VERSION}")

    skills_dir = root / "skills"
    for name in EXPECTED_SKILLS:
        skill = skills_dir / name / "SKILL.md"
        if not skill.is_file():
            errors.append(f"missing skill {skill}")

    commands_dir = root / "commands"
    for name in EXPECTED_COMMANDS:
        cmd = commands_dir / f"{name}.md"
        if not cmd.is_file():
            errors.append(f"missing command {cmd}")

    extra_cmds = sorted(
        p.stem for p in commands_dir.glob("*.md") if p.stem not in EXPECTED_COMMANDS
    )
    if extra_cmds:
        errors.append(f"unexpected commands: {extra_cmds}")

    for name in PREVIEW_APPLY_COMMANDS:
        text = (commands_dir / f"{name}.md").read_text(encoding="utf-8")
        if "yaaif_agent_spec_sync_preview" not in text:
            errors.append(f"commands/{name}.md missing yaaif_agent_spec_sync_preview")
        if "yaaif_agent_spec_sync_apply" not in text:
            errors.append(f"commands/{name}.md missing yaaif_agent_spec_sync_apply")
        if "yaaif_agent_spec_sync_to_objects" in text or "yaaif_agent_spec_sync_from_objects" in text:
            errors.append(
                f"commands/{name}.md still names stale sync_to_objects/sync_from_objects"
            )

    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        default=str(Path(__file__).resolve().parents[1]),
        help="cursor-plugin root",
    )
    args = parser.parse_args(argv)
    root = Path(args.root).expanduser().resolve()
    errors = check_inventory(root)
    if errors:
        print("check-plugin failed:", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        return 1
    print("check-plugin ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
