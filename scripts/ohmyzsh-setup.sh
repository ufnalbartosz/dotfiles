#!/usr/bin/env bash
# Install the external Oh My Zsh plugins and point ~/.zshrc at the plugin list.
# Idempotent. Oh My Zsh itself is not installed here (its installer replaces ~/.zshrc);
# if it is missing this prints the install command and exits cleanly.
set -euo pipefail

ZSHRC="$HOME/.zshrc"
OMZ_DIR="${ZSH:-$HOME/.oh-my-zsh}"
OMZ_CUSTOM="${ZSH_CUSTOM:-$OMZ_DIR/custom}"

# Built-in plugins first; zsh-syntax-highlighting must stay last.
PLUGINS="git fzf z sudo extract gh macos copypath colored-man-pages zsh-autosuggestions zsh-syntax-highlighting"

echo "Setting up Oh My Zsh plugins..."

if [ ! -d "$OMZ_DIR" ]; then
    echo "  Oh My Zsh not found at $OMZ_DIR — install it first, then re-run:"
    # The command substitution is meant to be printed literally, not expanded here.
    # shellcheck disable=SC2016
    echo '      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
    exit 0
fi

clone_plugin_if_missing() {
    local name="$1" url="$2"
    local dest="$OMZ_CUSTOM/plugins/$name"
    if [ -d "$dest" ]; then
        echo "  $name: already installed"
    else
        git clone --quiet --depth 1 "$url" "$dest"
        echo "  $name: cloned"
    fi
}

mkdir -p "$OMZ_CUSTOM/plugins"
clone_plugin_if_missing zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions
clone_plugin_if_missing zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting

# Only rewrite the stock `plugins=(git)` line; never overwrite a customized list.
touch "$ZSHRC"
if grep -Fq "zsh-syntax-highlighting" "$ZSHRC"; then
    echo "  .zshrc: plugin list already configured"
elif grep -Eq '^plugins=\(git\)[[:space:]]*$' "$ZSHRC"; then
    tmp="$(mktemp)"
    sed -E "s/^plugins=\(git\)[[:space:]]*$/plugins=($PLUGINS)/" "$ZSHRC" > "$tmp"
    cat "$tmp" > "$ZSHRC" && rm -f "$tmp"
    echo "  .zshrc: set plugins=($PLUGINS)"
else
    echo "  .zshrc: custom plugins=(...) line found, leaving it alone. Desired list:"
    echo "      plugins=($PLUGINS)"
fi
