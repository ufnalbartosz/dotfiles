#!/bin/bash
# Desktop notification for Claude Code hooks (Stop, Notification).
# usage: notify.sh <default message> [sound]   (hook JSON arrives on stdin)
# Always exits 0 so a notification problem never disturbs the session.

input=$(cat)
msg=$(jq -r '.message // empty' <<<"$input" 2>/dev/null)
cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)

msg=${msg:-$1}
sound=${2:-Glass}
where=$(basename "${cwd:-$PWD}")
# Inside tmux (ccs sessions), prefix the tmux session name so you know which one pinged.
if [ -n "$TMUX_PANE" ]; then
  session=$(tmux display-message -p -t "$TMUX_PANE" '#S' 2>/dev/null)
  [ -n "$session" ] && where="$session · $where"
fi

# Pass text as argv, not interpolated, so quotes in the message can't break the script.
osascript \
  -e 'on run argv' \
  -e 'display notification (item 1 of argv) with title (item 2 of argv) sound name (item 3 of argv)' \
  -e 'end run' \
  -- "$msg" "Claude Code — $where" "$sound" >/dev/null 2>&1

exit 0
