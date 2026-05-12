# Terminal search and preview tools.

# Quick file search with preview using fzf and bat.
alias p="fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'"

# Interactive ripgrep: search text within files with a live preview.
fif() {
  if [ "$#" -eq 0 ]; then
    echo "usage: fif <search phrase>" >&2
    return 2
  fi

  local query="$*"
  rg --column --line-number --no-heading --color=always --smart-case "$query" | fzf \
    --ansi \
    --color "hl:-1:underline,hl+:-1:underline:reverse" \
    --delimiter : \
    --preview 'bat --color=always --style=numbers --highlight-line {2} {1}' \
    --preview-window 'up,60%,border-bottom,+{2}+3/3' \
    --bind "enter:become(vim {1} +{2})"
}
