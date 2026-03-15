# dotfiles

Personal config files for Cursor and dev tooling docs.

## What's here

| Path | Symlinked to |
|------|-------------|
| `cursor/keybindings.json` | `~/Library/Application Support/Cursor/User/keybindings.json` |
| `cursor/settings.json` | `~/Library/Application Support/Cursor/User/settings.json` |
| `docs/python-dev-tooling-setup.md` | reference only, no symlink |

## New machine setup

```sh
git clone <repo-url> ~/dotfiles
cd ~/dotfiles && bash setup.sh
```

`setup.sh` will back up any existing Cursor config files (as `.bak`) before creating symlinks.

## Verify keybindings

Open Cursor and check:
- `Cmd+\` — toggle focus between editor and terminal
- `Ctrl+X Ctrl+C` — new terminal
- `Ctrl+X M` — maximize panel
