#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURSOR_DIR="$HOME/Library/Application Support/Cursor/User"

echo "Setting up dotfiles from $DOTFILES"

# Install Homebrew dependencies
if command -v brew &>/dev/null; then
    echo "Installing Homebrew packages..."
    brew bundle --file="$DOTFILES/Brewfile"
else
    echo "  ⚠ Homebrew not found — install from https://brew.sh then re-run setup.sh"
fi

# Install Claude Code (requires node)
if command -v npm &>/dev/null && ! command -v claude &>/dev/null; then
    echo "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
fi

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

# Seed ~/.cursor/mcp.json (copy-once — GitLens overwrites on updates)
if [ ! -f "$HOME/.cursor/mcp.json" ]; then
    mkdir -p "$HOME/.cursor"
    cp "$DOTFILES/cursor/mcp.json" "$HOME/.cursor/mcp.json"
    echo "  mcp.json: seeded from template"
    echo "  ⚠ Edit ~/.cursor/mcp.json — add GITHUB_PERSONAL_ACCESS_TOKEN"
else
    echo "  ~/.cursor/mcp.json: already exists, skipping"
fi

# Symlink custom Cursor extensions
CURSOR_EXT_DIR="$HOME/.cursor/extensions"
mkdir -p "$CURSOR_EXT_DIR"
for ext in "$DOTFILES/cursor/extensions"/*/; do
    ext_name=$(basename "$ext")
    ln -sf "$ext" "$CURSOR_EXT_DIR/$ext_name"
    echo "  extension: symlinked $ext_name"
done

# Claude Code setup
bash "$DOTFILES/claude-setup.sh"
