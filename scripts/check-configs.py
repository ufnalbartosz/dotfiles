#!/usr/bin/env python3
"""Sanity-check the repo's config files. Run by CI and safe to run locally.

- JSONC files parse once whole-line // comments are stripped.
- worktrunk/config.toml parses as TOML (Python 3.11+ only; skipped otherwise).
- Every package in Brewfile has a matching install call in scripts/setup.sh,
  so the manifest and the script can't drift apart silently.
"""

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

JSONC_FILES = (
    "cursor/settings.json",
    "cursor/keybindings.json",
    "cursor/mcp.json",
    "claude/settings.json",
)

failures = []


def check_jsonc(rel_path: str) -> None:
    path = REPO / rel_path
    text = re.sub(r"^\s*//.*$", "", path.read_text(), flags=re.M)
    try:
        json.loads(text)
    except json.JSONDecodeError as error:
        failures.append(f"{rel_path}: {error}")


def check_toml(rel_path: str) -> None:
    try:
        import tomllib
    except ModuleNotFoundError:
        print(f"skipping {rel_path} (tomllib needs Python 3.11+)")
        return
    path = REPO / rel_path
    try:
        tomllib.loads(path.read_text())
    except tomllib.TOMLDecodeError as error:
        failures.append(f"{rel_path}: {error}")


def check_brewfile_sync() -> None:
    setup = (REPO / "scripts" / "setup.sh").read_text()
    for brewfile in ("Brewfile", "Brewfile.extras"):
        for kind, name in re.findall(
            r'^(brew|cask) "([^"]+)"', (REPO / brewfile).read_text(), flags=re.M
        ):
            pattern = rf'install_brew_{"formula" if kind == "brew" else "cask"}_if_missing {re.escape(name)}\b'
            if not re.search(pattern, setup):
                failures.append(f"{brewfile}: {name} has no install call in scripts/setup.sh")


def main() -> int:
    for rel_path in JSONC_FILES:
        check_jsonc(rel_path)
    check_toml("worktrunk/config.toml")
    check_brewfile_sync()

    if failures:
        for failure in failures:
            print(f"FAIL {failure}", file=sys.stderr)
        return 1
    print("configs OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
