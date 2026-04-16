#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Setting up Claude Code config..."

# Seed ~/.claude/settings.json only if it does NOT already exist
if [ ! -f "$HOME/.claude/settings.json" ]; then
    mkdir -p "$HOME/.claude"
    cp "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
    echo "  settings.json: seeded from template"
    echo "  Edit ~/.claude/settings.json — add GITHUB_PERSONAL_ACCESS_TOKEN"
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

# Symlink user-level skills from dotfiles
if [ -d "$DOTFILES/claude/skills" ]; then
    mkdir -p "$HOME/.claude/skills"
    for skill_dir in "$DOTFILES/claude/skills"/*/; do
        [ -d "$skill_dir" ] || continue
        skill_name="$(basename "$skill_dir")"
        target="$HOME/.claude/skills/$skill_name"
        if [ -L "$target" ] || [ ! -e "$target" ]; then
            ln -sfn "$skill_dir" "$target"
            echo "  skill linked: $skill_name"
        else
            echo "  skill: $skill_name already exists (not a symlink), skipping"
        fi
    done
fi

echo "Claude Code setup done."
