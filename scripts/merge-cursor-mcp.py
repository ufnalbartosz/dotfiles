#!/usr/bin/env python3
"""Merge the template MCP servers into ~/.cursor/mcp.json.

The file can't be a symlink (GitLens rewrites it, silently dropping every
template server), so setup runs this merge instead of a copy-once seed:
template servers missing from the live file are re-added, while live-only
servers (e.g. GitLens's GitKraken) and existing values — tokens included —
are never touched.

A github server added with a placeholder token gets the real one from
`gh auth token` when available. Overrides for tests: $DOTFILES, $CURSOR_HOME,
$SKIP_GH.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path

DOTFILES = Path(os.environ.get("DOTFILES", Path(__file__).resolve().parent.parent))
CURSOR_HOME = Path(os.environ.get("CURSOR_HOME", Path.home() / ".cursor"))

TOKEN_PLACEHOLDER = "<your-token-here>"


def gh_token() -> str | None:
    if os.environ.get("SKIP_GH"):
        return None
    try:
        return subprocess.check_output(
            ["gh", "auth", "token"], text=True, stderr=subprocess.DEVNULL
        ).strip() or None
    except (OSError, subprocess.CalledProcessError):
        return None


def fill_placeholder_tokens(server: dict) -> None:
    env = server.get("env", {})
    for key, value in env.items():
        if value == TOKEN_PLACEHOLDER:
            token = gh_token()
            if token:
                env[key] = token
            else:
                print(f"  mcp.json: set {key} manually (gh auth token unavailable)")


def main() -> None:
    template = json.loads((DOTFILES / "cursor" / "mcp.json").read_text())
    live_path = CURSOR_HOME / "mcp.json"
    live = json.loads(live_path.read_text()) if live_path.exists() else {}
    live_servers = live.get("mcpServers", {})

    missing = [name for name in template.get("mcpServers", {}) if name not in live_servers]
    if not missing:
        print("  mcp.json: all template servers present, skipping")
        return

    for name in missing:
        server = json.loads(json.dumps(template["mcpServers"][name]))
        fill_placeholder_tokens(server)
        live_servers[name] = server
    live["mcpServers"] = live_servers

    if live_path.exists():
        shutil.copy2(live_path, f"{live_path}.bak")
    CURSOR_HOME.mkdir(parents=True, exist_ok=True)
    live_path.write_text(json.dumps(live, indent=2) + "\n")
    print(f"  mcp.json: restored template servers: {', '.join(sorted(missing))}")


if __name__ == "__main__":
    main()
