#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Setting up Claude Code config..."

# Seed ~/.claude/settings.json only if it does NOT already exist
if [ ! -f "$HOME/.claude/settings.json" ]; then
    mkdir -p "$HOME/.claude"
    cp "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
    echo "  settings.json: seeded from template"
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

# Symlink hook scripts (referenced from settings.json as $HOME/.claude/hooks/...)
mkdir -p "$HOME/.claude/hooks"
for hook in "$DOTFILES/claude/hooks"/*.sh; do
    [ -f "$hook" ] || continue
    hook_name="$(basename "$hook")"
    target="$HOME/.claude/hooks/$hook_name"
    if [ -L "$target" ] || [ ! -e "$target" ]; then
        ln -sfn "$hook" "$target"
        echo "  hook linked: $hook_name"
    else
        echo "  hook: $hook_name already exists (not a symlink), skipping"
    fi
done

# Symlink the global CLAUDE.md (Python conventions); never clobber a real file
target="$HOME/.claude/CLAUDE.md"
if [ -L "$target" ] || [ ! -s "$target" ]; then
    ln -sfn "$DOTFILES/claude/CLAUDE.md" "$target"
    echo "  CLAUDE.md: linked"
else
    echo "  CLAUDE.md: already exists (not a symlink), skipping"
fi

echo "Claude Code setup done."
