#!/usr/bin/env python3
"""Report drift between live machine config and the dotfiles repo templates.

Checks:
  1. ~/.claude/settings.json vs claude/settings.json (template)
  2. live enabledPlugins vs claude/plugins.txt
  3. ~/.cursor/mcp.json vs cursor/mcp.json (env values compared by presence
     only — secrets are never printed)
  4. uncommitted changes in the dotfiles repo itself

Exit 0 when everything is in sync, 1 when there is drift to reconcile.
Paths are overridable for testing: $DOTFILES, $CLAUDE_DIR, $CURSOR_HOME,
$SKIP_GIT_CHECK.
"""

from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path
from typing import Any

DOTFILES = Path(os.environ.get("DOTFILES", Path.home() / "dotfiles"))
CLAUDE_DIR = Path(os.environ.get("CLAUDE_DIR", Path.home() / ".claude"))
CURSOR_HOME = Path(os.environ.get("CURSOR_HOME", Path.home() / ".cursor"))

# Intentional live-vs-template differences. Add a path prefix here when a
# machine-only setting is permanent (plan-pinned model, extras-only servers).
IGNORE_PATHS = (
    "model",
    "mcpServers.snyk",
)

# Cursor mcp.json entries owned by the editor (GitLens injects GitKraken);
# never treat them as drift.
CURSOR_IGNORE_PATHS = ("mcpServers.GitKraken",)

drift: list[str] = []


def flatten(value: Any, prefix: str = "") -> dict[str, Any]:
    if not isinstance(value, dict):
        return {prefix: value}
    flat: dict[str, Any] = {}
    for key, child in value.items():
        path = f"{prefix}.{key}" if prefix else key
        flat.update(flatten(child, path))
    return flat


def ignored(path: str, prefixes: tuple[str, ...] = IGNORE_PATHS) -> bool:
    return any(path == p or path.startswith(p + ".") for p in prefixes)


def load(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        return None
    return json.loads(path.read_text())


def check_claude_settings() -> None:
    live = load(CLAUDE_DIR / "settings.json")
    template = load(DOTFILES / "claude" / "settings.json")
    if live is None or template is None:
        drift.append("claude-settings: live or template settings.json missing")
        return

    flat_live, flat_template = flatten(live), flatten(template)
    for path in sorted(set(flat_live) | set(flat_template)):
        if ignored(path):
            continue
        if path not in flat_template:
            drift.append(
                f"claude-settings: {path} = {flat_live[path]!r} only in live "
                "(sync into template, or add to IGNORE_PATHS if machine-only)"
            )
        elif path not in flat_live:
            drift.append(
                f"claude-settings: {path} = {flat_template[path]!r} only in template (apply to live?)"
            )
        elif flat_live[path] != flat_template[path]:
            drift.append(
                f"claude-settings: {path} live={flat_live[path]!r} vs template={flat_template[path]!r}"
            )


def check_plugins() -> None:
    live = load(CLAUDE_DIR / "settings.json") or {}
    enabled = {name for name, on in live.get("enabledPlugins", {}).items() if on}
    manifest_path = DOTFILES / "claude" / "plugins.txt"
    manifest = {
        line.strip()
        for line in manifest_path.read_text().splitlines()
        if line.strip()
    } if manifest_path.exists() else set()

    for plugin in sorted(manifest - enabled):
        drift.append(f"plugins: {plugin} in plugins.txt but not enabled live")
    for plugin in sorted(enabled - manifest):
        drift.append(f"plugins: {plugin} enabled live but missing from plugins.txt")


def check_cursor_mcp() -> None:
    live = load(CURSOR_HOME / "mcp.json")
    template = load(DOTFILES / "cursor" / "mcp.json")
    if live is None or template is None:
        return  # copy-once file; absence on either side isn't drift to commit

    flat_live, flat_template = flatten(live), flatten(template)
    for path in sorted(set(flat_live) | set(flat_template)):
        if ignored(path, CURSOR_IGNORE_PATHS):
            continue
        in_live, in_template = path in flat_live, path in flat_template
        if ".env." in path:
            # secrets: compare presence only, never print values
            if not in_live or not in_template:
                where = "live" if in_live else "template"
                drift.append(f"cursor-mcp: {path} only in {where} (value redacted)")
        elif not in_live or not in_template:
            where = "live" if in_live else "template"
            value = flat_live.get(path, flat_template.get(path))
            drift.append(f"cursor-mcp: {path} = {value!r} only in {where}")
        elif flat_live[path] != flat_template[path]:
            drift.append(
                f"cursor-mcp: {path} live={flat_live[path]!r} vs template={flat_template[path]!r}"
            )


def check_repo_clean() -> None:
    if os.environ.get("SKIP_GIT_CHECK"):
        return
    status = subprocess.check_output(
        ["git", "-C", str(DOTFILES), "status", "--porcelain"], text=True
    ).strip()
    if status:
        drift.append("repo: uncommitted changes in dotfiles:\n  " + "\n  ".join(status.splitlines()))


def main() -> int:
    check_claude_settings()
    check_plugins()
    check_cursor_mcp()
    check_repo_clean()

    if not drift:
        print("No drift: live config matches the dotfiles templates.")
        return 0
    print(f"{len(drift)} drift item(s):")
    for item in drift:
        print(f"  - {item}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
