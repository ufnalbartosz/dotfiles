#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up Claude Code config..."

# Seed ~/.claude/settings.json only if it does NOT already exist
if [ ! -f "$HOME/.claude/settings.json" ]; then
    mkdir -p "$HOME/.claude"
    cp "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
    echo "  settings.json: seeded from template"
    echo "  ⚠ Edit ~/.claude/settings.json — add GITHUB_PERSONAL_ACCESS_TOKEN"
else
    echo "  settings.json: already exists, skipping"
fi

# Install plugins from plugins.txt
echo "Installing Claude Code plugins..."
while IFS= read -r plugin; do
    [ -z "$plugin" ] && continue
    echo "  installing $plugin"
    claude plugin install "$plugin" || true
done < "$DOTFILES/claude/plugins.txt"

echo "Claude Code setup done."
