# Cursor: Python Test Explorer + Debugger Setup

Per-project config to get the Test Explorer GUI and breakpoint debugging working in Cursor for pytest projects.

---

## Required Extensions

Install once from the Extensions panel (Cursor reads VS Code Marketplace):

| Extension ID | Purpose |
|---|---|
| `ms-python.python` | Test discovery, Test Explorer integration |
| `ms-python.debugpy` | Debugger engine (auto-installed with Python extension) |
| `ms-python.pylance` | IntelliSense + type checking |

Or just open a project that has `.vscode/extensions.json` — Cursor will prompt you to install recommended extensions.

---

## Quick Setup for a New Project

Copy the template from dotfiles:

```sh
cp -r ~/dotfiles/templates/python-project/.vscode ./.vscode
```

Then adjust `"python.testing.pytestArgs"` in `.vscode/settings.json` if your tests aren't in a `tests/` directory.

---

## Files

### `.vscode/settings.json`

```json
{
    "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
    "python.testing.pytestEnabled": true,
    "python.testing.unittestEnabled": false,
    "python.testing.cwd": "${workspaceFolder}",
    "python.testing.pytestArgs": ["tests", "-v", "--tb=short"],
    "python.testing.autoTestDiscoverOnSave": true,
    "testing.defaultGutterClickAction": "run",
    "python.analysis.typeCheckingMode": "basic"
}
```

### `.vscode/launch.json`

The key field is `"purpose": ["debug-test"]` — this is what connects the config to Test Explorer's debug button.

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug Tests (Test Explorer)",
            "type": "debugpy",
            "request": "launch",
            "purpose": ["debug-test"],
            "console": "integratedTerminal",
            "justMyCode": false,
            "env": { "PYTEST_ADDOPTS": "--no-cov" }
        }
    ]
}
```

---

## Workflow

1. Open Testing panel: flask icon in Activity Bar, or `Cmd+Shift+P` → "Testing: Focus on Test Explorer View"
2. Click "Refresh Tests" if tests don't appear automatically
3. Set breakpoint: click in the editor gutter (red dot appears)
4. Right-click a test in Test Explorer → **Debug Test**, or click the bug icon next to the test

---

## Gotcha: Breakpoints Ignored

If breakpoints are silently skipped, `pytest-cov` is likely intercepting the trace hook. The `"PYTEST_ADDOPTS": "--no-cov"` env var in `launch.json` disables it during debug runs. Do **not** add `--cov` to `pytestArgs` in `settings.json`.

---

## `.code-workspace` Files

Only needed for multi-root workspaces (multiple project folders open simultaneously). For single-folder projects, `.vscode/settings.json` is sufficient.

If you do use a `.code-workspace` file, Python testing settings must go in `.vscode/settings.json` (per-folder), not the top-level `settings` block of the workspace file.
