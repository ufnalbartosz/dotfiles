#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURSOR_DIR="$HOME/Library/Application Support/Cursor/User"
ZSHRC="$HOME/.zshrc"
GITCONFIG="$HOME/.gitconfig"
WITH_EXTRAS=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [--with-extras]

Options:
  --with-extras
            Install optional tooling in Brewfile.extras.
  -h, --help
            Show this help.
EOF
}

for arg in "$@"; do
    case "$arg" in
        --with-extras)
            WITH_EXTRAS=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            usage >&2
            exit 2
            ;;
    esac
done

echo "Setting up dotfiles from $DOTFILES"

install_brew_formula_if_missing() {
    local formula="$1"
    local binary="$2"

    if command -v "$binary" &>/dev/null; then
        echo "  $formula: $binary already available, skipping"
    else
        echo "  $formula: installing"
        brew install "$formula"
    fi
}

install_brew_cask_if_missing() {
    local cask="$1"
    local app_path="$2"
    local binary="${3:-}"

    if { [ -n "$binary" ] && command -v "$binary" &>/dev/null; } || [ -e "$app_path" ]; then
        echo "  $cask: already available, skipping"
    else
        echo "  $cask: installing"
        brew install --cask "$cask"
    fi
}

# Install Homebrew dependencies
if command -v brew &>/dev/null; then
    echo "Installing Homebrew packages..."
    install_brew_formula_if_missing git git
    install_brew_formula_if_missing gh gh
    install_brew_formula_if_missing git-delta delta
    install_brew_formula_if_missing node node
    install_brew_formula_if_missing ripgrep rg
    install_brew_formula_if_missing fzf fzf
    install_brew_formula_if_missing bat bat
    install_brew_formula_if_missing worktrunk wt
    install_brew_formula_if_missing direnv direnv
    install_brew_formula_if_missing uv uv
    install_brew_formula_if_missing pyright pyright
    install_brew_cask_if_missing cursor "/Applications/Cursor.app" cursor
    install_brew_cask_if_missing iterm2 "/Applications/iTerm.app"

    if [ "$WITH_EXTRAS" = true ]; then
        echo "Installing optional Homebrew packages..."
        install_brew_formula_if_missing snyk-cli snyk
    fi
else
    echo "  Homebrew not found — install from https://brew.sh then re-run setup.sh"
fi

# Source shell tools from ~/.zshrc without taking ownership of the whole file
touch "$ZSHRC"
shell_source="[ -f \"$DOTFILES/shell/terminal-tools.zsh\" ] && source \"$DOTFILES/shell/terminal-tools.zsh\""
if grep -Fq "shell/terminal-tools.zsh" "$ZSHRC"; then
    echo "  .zshrc: terminal tools already sourced"
else
    {
        printf "\n# Dotfiles terminal tools: fzf, bat, ripgrep\n"
        printf "%s\n" "$shell_source"
    } >> "$ZSHRC"
    echo "  .zshrc: added terminal tools source"
fi

# Include repo-managed Git config without replacing personal ~/.gitconfig
touch "$GITCONFIG"
git_include_path="$DOTFILES/git/gitconfig"
if git config --file "$GITCONFIG" --get-all include.path 2>/dev/null | grep -Fxq "$git_include_path"; then
    echo "  .gitconfig: dotfiles include already present"
else
    git config --file "$GITCONFIG" --add include.path "$git_include_path"
    echo "  .gitconfig: added dotfiles include"
fi

# Install Claude Code (requires node)
if command -v npm &>/dev/null && ! command -v claude &>/dev/null; then
    echo "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
fi

# Expose the Codex app-bundled CLI in shells that do not inherit the app PATH.
CODEX_APP_CLI="/Applications/Codex.app/Contents/Resources/codex"
LOCAL_BIN="$HOME/.local/bin"
if ! command -v codex &>/dev/null && [ -x "$CODEX_APP_CLI" ]; then
    mkdir -p "$LOCAL_BIN"
    ln -sf "$CODEX_APP_CLI" "$LOCAL_BIN/codex"
    echo "  codex: linked app-bundled CLI into $LOCAL_BIN"
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
    echo "  Edit ~/.cursor/mcp.json — add GITHUB_PERSONAL_ACCESS_TOKEN"
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
bash "$DOTFILES/scripts/claude-setup.sh"
