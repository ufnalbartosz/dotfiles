# Keep the Emacs line-editing keymap (Ctrl-A/E/K/W/Y, Alt-B/F, ...) in zsh.
# zsh silently switches to vi mode when $EDITOR or $VISUAL contains "vi", so pin
# it explicitly rather than relying on that default. Sourced last in ~/.zshrc.
bindkey -e
