# dotfiles

Personal config files for Cursor, Claude Code, and dev tooling docs.

## What's here

| Path | How it's applied |
|------|-----------------|
| `Brewfile` | Run via `brew bundle` by `setup.sh` |
| `cursor/keybindings.json` | Symlinked → `~/Library/Application Support/Cursor/User/keybindings.json` |
| `cursor/settings.json` | Symlinked → `~/Library/Application Support/Cursor/User/settings.json` |
| `cursor/mcp.json` | Copied once → `~/.cursor/mcp.json` (not symlinked — GitLens overwrites) |
| `claude/settings.json` | Copied once → `~/.claude/settings.json` (sanitized template, no secrets) |
| `claude/plugins.txt` | Read by `claude-setup.sh` to install plugins via CLI |
| `docs/python-dev-tooling-setup.md` | Reference only |
| `docs/claude-code-setup.md` | Reference only |

## New machine setup

```sh
git clone <repo-url> ~/dotfiles
cd ~/dotfiles && bash setup.sh
```

`setup.sh`:
- Installs all Homebrew packages from `Brewfile` (git, gh, node, uv, pyright, snyk, Cursor)
- Installs Claude Code via npm if not already present
- Backs up existing Cursor config files (as `.bak`) then symlinks them
- Seeds `~/.cursor/mcp.json` from template (skipped if already exists)
- Seeds `~/.claude/settings.json` from template (skipped if already exists)
- Installs all Claude Code plugins via `claude plugin install`

After running:
1. Authenticate GitHub CLI: `gh auth login` (once per machine)
2. Get your token: `gh auth token`
3. Paste it into `~/.claude/settings.json` → `GITHUB_PERSONAL_ACCESS_TOKEN`
4. Paste it into `~/.cursor/mcp.json` → `GITHUB_PERSONAL_ACCESS_TOKEN`

See `docs/claude-code-setup.md` for full details on the Claude Code and Cursor MCP setup.

## Verify keybindings

Open Cursor and check:
- `Cmd+\` — toggle focus between editor and terminal
- `Ctrl+X Ctrl+C` — new terminal
- `Ctrl+X M` — maximize panel
