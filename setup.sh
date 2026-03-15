#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURSOR_DIR="$HOME/Library/Application Support/Cursor/User"

echo "Setting up dotfiles from $DOTFILES"

# Create Cursor user dir if it doesn't exist (fresh machine)
mkdir -p "$CURSOR_DIR"

for file in keybindings.json settings.json; do
    src="$DOTFILES/cursor/$file"
    dest="$CURSOR_DIR/$file"

    if [ -L "$dest" ]; then
        echo "  $file: already a symlink, skipping"
    elif [ -f "$dest" ]; then
        backup="$dest.bak"
        echo "  $file: backing up existing file to $backup"
        mv "$dest" "$backup"
        ln -s "$src" "$dest"
        echo "  $file: symlinked"
    else
        ln -s "$src" "$dest"
        echo "  $file: symlinked"
    fi
done

echo "Done."
