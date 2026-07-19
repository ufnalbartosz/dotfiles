# dotfiles

Personal config files for Cursor, Claude Code, and dev tooling docs.

## What's here

| Path | How it's applied |
|------|-----------------|
| `Brewfile` | Homebrew package manifest mirrored by `scripts/setup.sh` |
| `Brewfile.extras` | Optional package manifest mirrored by `scripts/setup.sh --with-extras` |
| `git/gitconfig` | Included from `~/.gitconfig` by `scripts/setup.sh` |
| `shell/terminal-tools.zsh` | Sourced from `~/.zshrc` by `scripts/setup.sh` |
| `cursor/keybindings.json` | Symlinked → `~/Library/Application Support/Cursor/User/keybindings.json` |
| `cursor/settings.json` | Symlinked → `~/Library/Application Support/Cursor/User/settings.json` |
| `cursor/mcp.json` | Copied once → `~/.cursor/mcp.json` (not symlinked — GitLens overwrites) |
| `worktrunk/config.toml` | Symlinked → `~/.config/worktrunk/config.toml` — worktree hooks (CLAUDE.md copy, shared `.venv`, direnv `.envrc`) |
| `bin/update-workspace.py` | Symlinked → `~/.local/bin/update-workspace.py` — refreshes the multi-root `.code-workspace`; reads `~/.config/dotfiles/workspace.conf` |
| `claude/settings.json` | Copied once → `~/.claude/settings.json` (sanitized template, no secrets) |
| `claude/plugins.txt` | Read by `scripts/claude-setup.sh` to install plugins via CLI |
| `docs/python-dev-tooling-setup.md` | Reference only |
| `docs/claude-code-setup.md` | Reference only |

## New machine setup

```sh
git clone <repo-url> ~/dotfiles
cd ~/dotfiles && bash scripts/setup.sh
```

`scripts/setup.sh`:
- Installs missing Homebrew packages from the core manifest (git, gh, git-delta, ripgrep, fzf, bat, worktrunk, direnv, node, uv, pyright, Cursor, iTerm2)
- Skips installs when the expected binary or app already exists, even if it was not installed by Homebrew
- With `--with-extras`, also installs missing optional packages from `Brewfile.extras` (currently `snyk-cli`)
- Adds the repo-managed Git config include for delta-powered diffs
- Sources terminal search helpers from `~/.zshrc`
- Installs Claude Code via npm if not already present
- Links the Codex app-bundled CLI into `~/.local/bin` when needed
- Backs up existing Cursor config files (as `.bak`) then symlinks them
- Seeds `~/.cursor/mcp.json` from template (skipped if already exists)
- Seeds `~/.claude/settings.json` from template (skipped if already exists)
- Installs all Claude Code plugins via `claude plugin install`
- Symlinks the worktrunk config (`~/.config/worktrunk/config.toml`) and the workspace updater (`~/.local/bin/update-workspace.py`), backing up any existing files
- Prints how to set `~/.config/dotfiles/workspace.conf` if the workspace updater isn't pointed at a `.code-workspace` yet

After running:
1. Authenticate GitHub CLI: `gh auth login` (once per machine)
2. Get your token: `gh auth token`
3. Paste it into `~/.cursor/mcp.json` → `GITHUB_PERSONAL_ACCESS_TOKEN`

See `docs/claude-code-setup.md` for full details on the Claude Code and Cursor MCP setup.

## Terminal tools

The setup installs and configures:
- `delta` as the Git pager with side-by-side diffs, line numbers, navigation, and `zdiff3` merge conflicts
- `rg` / `git grep` for fast code search
- `worktrunk` (`wt`) for Git worktree management
- iTerm2 for semantic history / Cmd-click file path workflows
- Codex CLI from the Codex desktop app bundle, exposed as `codex` on your shell `PATH`
- `fzf` + `bat` helpers:
  - `p` opens an interactive file picker with syntax-highlighted previews
  - `fif <phrase>` searches file contents with ripgrep and opens the selected match in Vim

## Worktree workflow

`worktrunk` (`wt`) drives Git worktrees; `worktrunk/config.toml` adds hooks that make every new worktree usable immediately:

- **CLAUDE.md** — copied in from the main worktree (it's untracked, so git won't carry it).
- **Shared `.venv`** — symlinked to the main worktree's venv instead of re-running `uv sync`. The venv's scripts are absolute-path-pinned, so a symlink resolves everywhere; a copy would break. A branch that needs different deps gets its own: `rm .venv && uv sync`.
- **direnv `.envrc`** — written and auto-`direnv allow`ed so a plain terminal activates the venv on `cd` in. Requires the `direnv` shell hook (added by `shell/terminal-tools.zsh`).
- **Workspace refresh** — `post-start`/`post-remove` run `update-workspace.py` to keep the multi-root `.code-workspace` in sync with current worktrees, and to ensure editor settings (no global Python interpreter — each folder auto-detects its own `.venv`; Path Intellisense; markdown path completion).

`update-workspace.py` is repo-agnostic: it reads the target `.code-workspace` from `$DOTFILES_WORKSPACE_FILE` or `~/.config/dotfiles/workspace.conf` (a single line holding the path). With neither set it's a no-op, so the hooks are safe on any machine.

Because the hooks drop `CLAUDE.md` and `.envrc` into each worktree as untracked files, add both to your global gitignore (`core.excludesfile`, e.g. `~/.gitignore_global`) — otherwise `wt remove` treats them as uncommitted changes and refuses to clean up. (Trade-off: in a repo that doesn't yet track its `CLAUDE.md`, you'll need `git add -f CLAUDE.md` to start.)

## Verify keybindings

Open Cursor and check:
- `Cmd+\` — toggle focus between editor and terminal
- `Ctrl+X Ctrl+C` — new terminal
- `Ctrl+X M` — maximize panel

## Keybindings reference

<!-- BEGIN: generated keybindings table -->
<!-- source: cursor/keybindings.json -->
<!-- generator: gen-keybindings-doc.py — do not edit by hand; re-run the script to regenerate -->

| Chord | Command | When |
|-------|---------|------|
| `Cmd+I` | `composerMode.agent` | — |
| `Shift+enter` | `workbench.action.terminal.sendSequence` | `terminalFocus` |
| `Ctrl+X M` | `workbench.action.toggleMaximizedPanel` | — |
| `Alt+Cmd+S` | `workbench.action.toggleUnifiedSidebarFromKeyboard` | `cursor.agentIdeUnification.enabled == true && !isAuxiliaryWindowFocusedContext` |
| `Ctrl+X Ctrl+C` | `workbench.action.terminal.new` | `terminalFocus` |
| `Ctrl+X Ctrl+K` | `workbench.action.terminal.kill` | `terminalFocus` |
| `Ctrl+X up` | `workbench.action.terminal.focusPrevious` | `terminalFocus` |
| `Ctrl+X down` | `workbench.action.terminal.focusNext` | `terminalFocus` |
| `Cmd+\` | `workbench.action.terminal.focus` | `editorTextFocus` |
| `Cmd+\` | `workbench.action.focusActiveEditorGroup` | `terminalFocus` |
| `Cmd+\` | `-workbench.action.terminal.split` | `terminalFocus` |
| `Cmd+\` | `workbench.action.focusActiveEditorGroup` | `explorerViewletFocus` |
| `Ctrl+X Ctrl+Z` | `workbench.action.toggleZenMode` | — |
| `Ctrl+X Ctrl+G` | `gitlens.showGraphView` | — |
| `Ctrl+X Ctrl+E` | `workbench.view.explorer` | — |
| `Ctrl+X Ctrl+T` | `workbench.action.terminal.toggleTerminal` | — |
| `Ctrl+X Ctrl+S` | `workbench.action.files.save` | `editorTextFocus` |
| `Ctrl+X S` | `workbench.action.findInFiles` | — |
| `Ctrl+X O` | `workbench.action.focusFirstEditorGroup` | `terminalFocus` |
| `Ctrl+X O` | `workbench.action.focusSecondEditorGroup` | `editorTextFocus && activeEditorGroupIndex == 1 && multipleEditorGroups` |
| `Ctrl+X O` | `workbench.action.terminal.focus` | `editorTextFocus && activeEditorGroupIndex == 2` |
| `Ctrl+X O` | `workbench.action.terminal.focus` | `editorTextFocus && !multipleEditorGroups` |
| `Ctrl+X O` | `workbench.action.focusActiveEditorGroup` | `explorerViewletFocus` |
| `Ctrl+X Ctrl+I` | `editor.action.indentLines` | `editorTextFocus && !editorReadonly` |
| `Alt+Shift+P` | `editor.action.moveLinesUpAction` | `editorTextFocus && !editorReadonly` |
| `Alt+Shift+N` | `editor.action.moveLinesDownAction` | `editorTextFocus && !editorReadonly` |
| `Ctrl+X Ctrl+P` | `test-navigator.jumpTest` | `editorTextFocus` |
| `Cmd+.` | `editor.action.revealDefinition` | `editorHasDefinitionProvider && editorTextFocus` |
| `Ctrl+X Ctrl+Shift+P` | `test-navigator.createTest` | `editorTextFocus` |
| `Cmd+,` | `-workbench.action.openSettings` | — |
| `Cmd+,` | `workbench.action.navigateBack` | — |
| `Cmd+/` | `editor.action.commentLine` | `editorTextFocus && !editorReadonly` |
| `Ctrl+M` | `-editor.action.toggleTabFocusMode` | — |
| `Cmd+J` | `workbench.action.togglePanel` | — |
| `Cmd+J` | `-workbench.action.chat.toggleAgentMode` | — |
| `escape` | `workbench.action.chat.stopInChatSession` | `inChat` |
<!-- END: generated keybindings table -->
