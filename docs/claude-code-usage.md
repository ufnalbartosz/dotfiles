# Claude Code: day-to-day usage

How the pieces in this repo fit together when you run Claude Code from the terminal.
Setup lives in [`claude-code-setup.md`](claude-code-setup.md); this is the "how do I use it" side.

## Running sessions: `ccs`

`ccs` starts Claude Code inside tmux and keeps the Mac awake, so long runs survive a closed lid or a dropped terminal.

```sh
ccs                 # session named after the current directory (attach if it exists)
ccs api -r          # session "api", start claude with --resume
ccs --list          # what each session is running, attached or idle, sleep state
ccs -k api          # kill one (restores sleep if it was the last)
```

Detach with `Ctrl-b d`; the run keeps going. The Stop and Notification hooks (below) are what tell you it finished, so you don't need to watch the pane. Full option list: `ccs --help`.

## Hooks

Hook scripts live in `claude/hooks/` and are symlinked into `~/.claude/hooks/` by `scripts/claude-setup.sh`. They are wired up in `claude/settings.json` (copied to `~/.claude/settings.json` only on a fresh machine, so edit the live file too when you change one).

| Event | Script | What it does |
|-------|--------|--------------|
| `Stop` | `notify.sh` | macOS notification (Glass sound) when Claude finishes a turn. Inside tmux the title includes the session name. |
| `Notification` | `notify.sh` | Notification (Ping sound) when Claude is waiting on a permission prompt or input. |
| `PostToolUse` on `Write\|Edit` | `python-check.sh` | For `.py` files: `ruff format`, `ruff check --fix` plus Google-style docstring rules, then `mypy --strict`. Problems are fed back to Claude. |
| `PreToolUse` on `Bash` | `precommit-gate.sh` | Only acts on `git commit`: lints staged Python, then runs `npm test` or pytest (via `uv run` when there is a `pyproject.toml`). A failure blocks the commit. |

Things worth knowing:

- **Notifications need permission.** If no banner appears, allow notifications for "Script Editor" in System Settings → Notifications (the script uses `osascript`).
- **Docstrings: format, not presence.** The missing-docstring rules (D100-D107) are ignored on purpose. Remove `--extend-ignore` in `python-check.sh` to require them.
- **mypy first run is slow** in projects without mypy (`uvx` downloads it). `uv add --dev mypy` fixes that.
- **Tests run at commit time, not on every edit.** Per-edit test runs are slow and noisy.
- **Review, disable or edit** hooks from the `/hooks` menu. Settings changes made outside a session need a restart or one visit to `/hooks`.
- `claude --bare` skips hooks entirely, handy for debugging a hook that misbehaves.

## Memory

Three layers, from most to least deliberate:

1. **`~/.claude/CLAUDE.md`** (this repo: `claude/CLAUDE.md`, symlinked): standing instructions for every project. Currently the Python conventions (uv, ruff, `mypy --strict`, Google docstrings). A project's own `CLAUDE.md` adds to it.
2. **`/memory`** opens the CLAUDE.md files and the memory settings for editing.
3. **Auto-memory**: Claude saves notes about you and your projects as files in `~/.claude/projects/<project>/memory/`, with a `MEMORY.md` index loaded each session. Related settings: `autoMemoryEnabled`, `autoMemoryDirectory`, `autoDreamEnabled` (background consolidation).

Practical use:

- Put *rules* in `CLAUDE.md`. Put *facts about you and ongoing work* in memory.
- Say it plainly: "remember that I prefer X because Y" or "forget what you saved about Z". Memory files are plain markdown, so you can read, edit or delete them.
- Memory is a hint, not a source of truth. If a note names a file or flag, expect Claude to verify it still exists.
- Never put secrets in either place.

## Advisor

`/advisor [model|off]` lets Claude consult a stronger model at key moments. The model is also stored as the `advisorModel` setting.

Suggested use: keep a faster default model (this machine defaults to Sonnet) and turn the advisor on for work where a second opinion pays off, such as architecture decisions, tricky debugging, or reviewing a large diff before you commit. Turn it off with `/advisor off` for routine edits. The command's hint is `[model|off]`, so pass a model name to enable it.

## Zsh and Oh My Zsh

`scripts/setup.sh` runs `scripts/ohmyzsh-setup.sh`, which clones the two external plugins and sets the plugin list (only when `~/.zshrc` still has the stock `plugins=(git)`):

```zsh
plugins=(git fzf z sudo extract gh macos copypath colored-man-pages zsh-autosuggestions zsh-syntax-highlighting)
```

| Plugin | Use |
|--------|-----|
| `zsh-autosuggestions` | Gray history suggestion as you type; `→` accepts |
| `zsh-syntax-highlighting` | Valid commands green, typos red. Keep it last in the list |
| `fzf` | `Ctrl-R` fuzzy history, `Ctrl-T` fuzzy file picker |
| `z` | `z proj` jumps to a frequently used directory |
| `sudo` | `Esc Esc` prepends `sudo` |
| `extract` | `x archive.tar.gz` unpacks anything |
| `copypath`, `macos`, `gh`, `colored-man-pages` | Clipboard path, Finder helpers, GitHub CLI completions, readable man pages |

Each plugin adds shell startup time, so add only what you use.

## Emacs-style keys

Emacs line editing is configured explicitly everywhere, with no dependency on any Oh My Zsh editor plugin:

| Where | How |
|-------|-----|
| zsh | `shell/zsh-keys.zsh` runs `bindkey -e`. Without it zsh would flip to vi mode if `$EDITOR` ever contained "vi". |
| vim | `vim/vimrc`: Emacs keys in insert and command-line mode |
| tmux | `tmux/tmux.conf`: `mode-keys emacs`, `status-keys emacs` |
| Cursor | `cursor/keybindings.json` |
| Claude Code prompt | Uses readline-style keys (`Ctrl-A`, `Ctrl-E`, `Ctrl-K`, `Ctrl-W`) out of the box; `editorMode` stays `normal` |
