#!/usr/bin/env python3
"""Keep a VS Code / Cursor multi-root .code-workspace in sync with git worktrees.

Every source folder's worktrees are discovered and added as workspace folders,
and a small set of editor settings is guaranteed on each run.

The target .code-workspace is machine-local (it points at wherever you keep your
checkouts), so it is NOT hardcoded here. Resolve order:
  1. $DOTFILES_WORKSPACE_FILE
  2. ~/.config/dotfiles/workspace.conf  (a single line: the path to the file)
If neither is set, this is a no-op so the script is safe to ship and to wire into
worktree hooks on any machine.
"""

from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path
from typing import Any


def resolve_workspace_file() -> Path | None:
    env = os.environ.get("DOTFILES_WORKSPACE_FILE")
    if env:
        return Path(env).expanduser()
    conf = Path.home() / ".config" / "dotfiles" / "workspace.conf"
    if conf.exists():
        text = conf.read_text().strip()
        if text:
            return Path(text).expanduser()
    return None


WORKSPACE_PATH = resolve_workspace_file()
WORKSPACE_ROOT = WORKSPACE_PATH.parent if WORKSPACE_PATH else None

# Settings guaranteed on every run. Deliberately NO workspace-wide
# python.defaultInterpreterPath: the workspace mixes Python repos (each with its
# own .venv, which Cursor auto-detects per folder) and venv-less / non-Python
# folders, so any single global interpreter path is invalid for some folder and
# triggers "Invalid Python interpreter selected". activateEnvironment + the
# create-env trigger keep terminals quiet; Path Intellisense + markdown give path
# autocomplete inside files.
DESIRED_SETTINGS: dict[str, Any] = {
    "python.terminal.activateEnvironment": True,
    "python.createEnvironment.trigger": "off",
    "path-intellisense.autoTriggerNextSuggestion": True,
    "path-intellisense.extensionOnImport": True,
    "path-intellisense.showHiddenFiles": True,
    "markdown.suggest.paths.enabled": True,
}

# Workspace-level settings we actively remove if present — a global interpreter
# path is the cause of the invalid-interpreter popups, so we never let one persist.
REMOVE_SETTINGS = ("python.defaultInterpreterPath",)

# Machine/org-specific settings (GitHub Enterprise URI, proxies, …) stay out of
# the repo: put them in this untracked overlay and they win over DESIRED_SETTINGS.
LOCAL_SETTINGS_PATH = Path.home() / ".config" / "dotfiles" / "workspace.settings.json"


def local_settings() -> dict[str, Any]:
    if not LOCAL_SETTINGS_PATH.exists():
        return {}
    try:
        loaded = json.loads(LOCAL_SETTINGS_PATH.read_text())
    except json.JSONDecodeError as error:
        print(f"Ignoring {LOCAL_SETTINGS_PATH}: {error}")
        return {}
    return loaded if isinstance(loaded, dict) else {}


def ensure_settings(settings: dict[str, Any]) -> dict[str, Any]:
    merged = dict(settings)
    for key in REMOVE_SETTINGS:
        merged.pop(key, None)
    merged.update(DESIRED_SETTINGS)
    merged.update(local_settings())
    return merged


def run_git(args: list[str], cwd: Path) -> str | None:
    try:
        return subprocess.check_output(
            ["git", "-C", str(cwd), *args],
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
    except subprocess.CalledProcessError:
        return None


def is_relative_to(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
    except ValueError:
        return False
    return True


def load_workspace() -> dict[str, Any]:
    assert WORKSPACE_PATH is not None
    return json.loads(WORKSPACE_PATH.read_text())


def resolve_workspace_path(path_value: str) -> Path:
    assert WORKSPACE_ROOT is not None
    path = Path(path_value).expanduser()
    if path.is_absolute():
        return path.resolve()
    return (WORKSPACE_ROOT / path).resolve()


def workspace_path(path: Path) -> str:
    assert WORKSPACE_ROOT is not None
    resolved_path = path.resolve()
    if is_relative_to(resolved_path, WORKSPACE_ROOT):
        return str(resolved_path.relative_to(WORKSPACE_ROOT))
    return str(resolved_path)


def parse_worktree_list(output: str) -> list[dict[str, str]]:
    worktrees: list[dict[str, str]] = []
    current: dict[str, str] = {}

    for line in output.splitlines():
        if not line:
            if current:
                worktrees.append(current)
                current = {}
            continue

        key, _, value = line.partition(" ")
        if key == "worktree":
            current["path"] = value
        elif key == "branch":
            current["branch"] = value.removeprefix("refs/heads/")
        elif key == "detached":
            current["branch"] = "detached"

    if current:
        worktrees.append(current)

    return worktrees


def repo_worktrees(repo_root: Path) -> list[dict[str, str]]:
    assert WORKSPACE_ROOT is not None
    output = run_git(["worktree", "list", "--porcelain"], repo_root)
    if output is None:
        return []

    return [
        worktree
        for worktree in parse_worktree_list(output)
        if "path" in worktree and is_relative_to(Path(worktree["path"]).resolve(), WORKSPACE_ROOT)
    ]


def primary_worktree_path(path: Path) -> Path | None:
    worktrees = repo_worktrees(path)
    if not worktrees:
        return None
    return Path(worktrees[0]["path"]).resolve()


def is_source_folder(path: Path) -> bool:
    inside_work_tree = run_git(["rev-parse", "--is-inside-work-tree"], path)
    if inside_work_tree != "true":
        return True

    top_level = run_git(["rev-parse", "--show-toplevel"], path)
    primary_path = primary_worktree_path(path)
    if top_level is None or primary_path is None:
        return True

    return Path(top_level).resolve() == primary_path


def source_folders(workspace: dict[str, Any]) -> list[dict[str, str]]:
    folders: list[dict[str, str]] = []
    seen_paths: set[str] = set()

    for folder in workspace.get("folders", []):
        if not isinstance(folder, dict):
            continue

        path_value = folder.get("path")
        if not isinstance(path_value, str):
            continue

        path = resolve_workspace_path(path_value)
        if not path.exists() or not is_source_folder(path):
            continue

        normalized_path = workspace_path(path)
        if normalized_path in seen_paths:
            continue

        source_folder = {"path": normalized_path}
        name = folder.get("name")
        if isinstance(name, str):
            source_folder["name"] = name

        folders.append(source_folder)
        seen_paths.add(normalized_path)

    return folders


def discover_repo_roots(sources: list[dict[str, str]]) -> list[Path]:
    repo_roots: list[Path] = []
    seen_roots: set[Path] = set()

    for source in sources:
        path = resolve_workspace_path(source["path"])
        top_level = run_git(["rev-parse", "--show-toplevel"], path)
        if top_level is None:
            continue

        repo_root = Path(top_level).resolve()
        if repo_root in seen_roots:
            continue

        repo_roots.append(repo_root)
        seen_roots.add(repo_root)

    return repo_roots


def folder_name(worktree: dict[str, str], used_names: set[str]) -> str:
    assert WORKSPACE_ROOT is not None
    path = Path(worktree["path"]).resolve()
    name = path.name

    if name not in used_names:
        used_names.add(name)
        return name

    unique_name = str(path.relative_to(WORKSPACE_ROOT))
    used_names.add(unique_name)
    return unique_name


def workspace_folders(workspace: dict[str, Any]) -> list[dict[str, str]]:
    used_names: set[str] = set()
    folders: list[dict[str, str]] = []
    seen_paths: set[str] = set()
    sources = source_folders(workspace)

    for source in sources:
        path = resolve_workspace_path(source["path"])
        normalized_path = workspace_path(path)
        name = source.get("name") or folder_name({"path": str(path)}, used_names)
        used_names.add(name)

        folders.append({"name": name, "path": normalized_path})
        seen_paths.add(normalized_path)

    for repo_root in discover_repo_roots(sources):
        for worktree in repo_worktrees(repo_root):
            path = Path(worktree["path"]).resolve()
            normalized_path = workspace_path(path)
            if normalized_path in seen_paths:
                continue

            folders.append(
                {
                    "name": folder_name(worktree, used_names),
                    "path": normalized_path,
                }
            )
            seen_paths.add(normalized_path)

    return sorted(folders, key=lambda folder: folder["path"])


def main() -> None:
    if WORKSPACE_PATH is None:
        print(
            "No workspace configured "
            "(set $DOTFILES_WORKSPACE_FILE or write ~/.config/dotfiles/workspace.conf); "
            "nothing to do."
        )
        return

    existing_workspace = load_workspace()
    workspace = {
        "folders": workspace_folders(existing_workspace),
        "settings": ensure_settings(existing_workspace.get("settings", {})),
    }

    WORKSPACE_PATH.write_text(json.dumps(workspace, indent=2) + "\n")
    print(f"Updated {WORKSPACE_PATH} with {len(workspace['folders'])} folders")


if __name__ == "__main__":
    main()
