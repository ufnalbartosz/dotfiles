# dotfiles

Personal config files for Cursor, Claude Code, and dev tooling docs.

## What's here

| Path | How it's applied |
|------|-----------------|
| `Brewfile` | Run via `brew bundle` by `scripts/setup.sh` |
| `cursor/keybindings.json` | Symlinked → `~/Library/Application Support/Cursor/User/keybindings.json` |
| `cursor/settings.json` | Symlinked → `~/Library/Application Support/Cursor/User/settings.json` |
| `cursor/mcp.json` | Copied once → `~/.cursor/mcp.json` (not symlinked — GitLens overwrites) |
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
- Installs all Homebrew packages from `Brewfile` (git, gh, node, uv, pyright, snyk, Cursor)
- Installs Claude Code via npm if not already present
- Backs up existing Cursor config files (as `.bak`) then symlinks them
- Seeds `~/.cursor/mcp.json` from template (skipped if already exists)
- Seeds `~/.claude/settings.json` from template (skipped if already exists)
- Installs all Claude Code plugins via `claude plugin install`

After running:
1. Authenticate GitHub CLI: `gh auth login` (once per machine)
2. Get your token: `gh auth token`
3. Paste it into `~/.cursor/mcp.json` → `GITHUB_PERSONAL_ACCESS_TOKEN`

See `docs/claude-code-setup.md` for full details on the Claude Code and Cursor MCP setup.

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
