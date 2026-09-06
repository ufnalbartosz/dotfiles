# ccs — "claude code session": Claude Code in tmux, with sleep held off for the
# session's lifetime. Depends on the sleep-* helpers in macos-sleep.zsh.

# Names of the tmux sessions we created (tagged with the @ccs session option).
# Session names can't contain ':' or '.', so the colon separator is unambiguous.
_ccs_managed() {
  tmux list-sessions -F '#{@ccs}:#{session_name}' 2>/dev/null | while IFS=: read -r tag session; do
    [[ "$tag" == 1 ]] && print -r -- "$session"
  done
}

# What a session's shell is actually running, or "idle" if it's just the shell.
# Reads the pane shell's foreground child via ps rather than tmux's
# #{pane_current_command}: Claude Code retitles its process to its version
# string, so tmux reports e.g. "2.1.263" where ps still reports "claude".
_ccs_activity() {
  local session="$1" pane_pid child cmd
  pane_pid=$(tmux list-panes -t "=${session}" -F '#{pane_pid}' 2>/dev/null | head -1)
  [[ -z "$pane_pid" ]] && { print -r -- "?"; return; }
  child=$(pgrep -P "$pane_pid" 2>/dev/null | head -1)
  if [[ -z "$child" ]]; then
    print -r -- "idle"
    return
  fi
  cmd=$(ps -o command= -p "$child" 2>/dev/null)
  cmd="${${(z)cmd}[1]}"
  cmd="${cmd:t}"
  print -r -- "${cmd:-?}"
}

# True when macOS currently has sleep disabled.
_ccs_sleep_disabled() {
  [[ "$(pmset -g 2>/dev/null | awk '/SleepDisabled/ {print $2}')" == 1 ]]
}

# Restore sleep, but only once the last ccs session is gone.
_ccs_restore_sleep() {
  local -a remaining
  remaining=("${(@f)$(_ccs_managed)}")
  remaining=("${(@)remaining:#}")
  if (( ${#remaining} == 0 )); then
    sleep-enabled
  else
    echo "ccs: ${#remaining} ccs session(s) still running — sleep left disabled"
  fi
}

ccs-help() {
  cat <<'EOF'
ccs — "claude code session"

ccs [name] [options] [-- claude-args...]

  name             session name (default: current directory name)
  -r, --resume     start claude with --resume
      --start      create the session detached and stay in this shell
                   (--open is accepted as a synonym)
  -S, --no-sleep   leave sleep settings alone
  -l, --list       list ccs sessions: what each is running (or "idle"),
                   whether it's attached, its path, and the sleep state
  -k, --kill NAME  kill a session, restoring sleep if it was the last one
  -k, --kill --all kill every ccs session, then restore sleep
      --restore    restore sleep now, without touching any session
  -h, --help       show this

With no options, ccs creates the session or attaches to an existing one.
Sleep is disabled when the session starts and restored when it exits.
Detaching (ctrl-b d) leaves sleep disabled so work continues with the lid shut.
--start never attaches, so sleep stays disabled until you attach and exit later.
EOF
}

ccs() {
  emulate -L zsh
  local name="" kill_target="" action="run"
  local resume=0 nosleep=0
  local -a claude_args

  while (( $# )); do
    case "$1" in
      -r|--resume)   resume=1 ;;
      # No -s short form: too easy to typo against -S/--no-sleep, and both
      # would silently do something plausible.
      --start|--open) action="start" ;;
      --restore)     action="restore" ;;
      -S|--no-sleep) nosleep=1 ;;
      -l|--list)     action="list" ;;
      -h|--help)     action="help" ;;
      -k|--kill)
        if [[ -z "$2" ]]; then
          echo "ccs: --kill needs a session name" >&2
          return 2
        fi
        action="kill"
        kill_target="$2"
        shift
        ;;
      --) shift; claude_args=("$@"); break ;;
      -*) echo "ccs: unknown option: $1" >&2; return 2 ;;
      *)
        if [[ -n "$name" ]]; then
          echo "ccs: unexpected argument: $1" >&2
          return 2
        fi
        name="$1"
        ;;
    esac
    shift
  done

  case "$action" in
    help) ccs-help; return 0 ;;
    list)
      # One tmux call for everything: display-message -p returns empty without
      # a client, and list-sessions resolves #{pane_current_path} against each
      # session's active pane. ':' can't appear in a tmux session name, and
      # path is read last, so the split is unambiguous.
      local tag sname attached spath marker found=0
      while IFS=: read -r tag sname attached spath; do
        [[ "$tag" == 1 ]] || continue
        if (( ! found )); then
          printf '  %-20s %-10s %-8s %s\n' SESSION RUNNING ATTACHED PATH
          found=1
        fi
        # Assigned, not echoed: zsh's echo eats a lone '-' as an option
        # terminator and would print an empty column.
        if [[ "$attached" == 0 ]]; then marker="-"; else marker="yes"; fi
        printf '  %-20s %-10s %-8s %s\n' \
          "$sname" "$(_ccs_activity "$sname")" "$marker" "${spath/#$HOME/~}"
      done < <(tmux list-sessions -F '#{@ccs}:#{session_name}:#{session_attached}:#{pane_current_path}' 2>/dev/null)
      (( found )) || echo "no ccs sessions"
      sleep-status
      # Sleep disabled with nothing running means a session died somewhere ccs
      # couldn't observe it (plain tmux kill, closed terminal window).
      if (( ! found )) && _ccs_sleep_disabled; then
        echo "ccs: stale — sleep is disabled with no ccs sessions; fix with: ccs --restore"
      fi
      return 0
      ;;
    kill)
      if [[ "$kill_target" == "--all" ]]; then
        local -a doomed
        doomed=("${(@f)$(_ccs_managed)}")
        doomed=("${(@)doomed:#}")
        if (( ! ${#doomed} )); then
          echo "ccs: no ccs sessions to kill"
        else
          local victim
          for victim in "${doomed[@]}"; do
            tmux kill-session -t "=${victim}" 2>/dev/null && echo "ccs: killed '$victim'"
          done
        fi
      else
        if tmux kill-session -t "=${kill_target}" 2>/dev/null; then
          echo "ccs: killed '$kill_target'"
        else
          # Already gone — still reconcile sleep below, since the whole point
          # of the kill (no session, sleep normal) may be half-done.
          echo "ccs: no such session: $kill_target" >&2
          _ccs_restore_sleep
          return 1
        fi
      fi
      _ccs_restore_sleep
      return 0
      ;;
    restore)
      local -a live
      live=("${(@f)$(_ccs_managed)}")
      live=("${(@)live:#}")
      (( ${#live} )) && echo "ccs: note — ${#live} ccs session(s) still running"
      sleep-enabled
      return 0
      ;;
  esac

  [[ -z "$name" ]] && name="${PWD:t}"
  name="${name//[.:]/-}"

  (( nosleep )) || sleep-disabled || return 1

  local created=0
  if ! tmux has-session -t "=${name}" 2>/dev/null; then
    local -a cmd=(claude)
    (( resume )) && cmd+=(--resume)
    (( ${#claude_args} )) && cmd+=("${claude_args[@]}")
    # Drop into a login shell when claude exits, so a crash doesn't take the
    # scrollback with it. The session ends when that shell exits.
    tmux new-session -d -s "$name" -c "$PWD" "${(j: :)${(q)cmd[@]}}; exec ${(q)SHELL} -l" || return 1
    # No '=' prefix here: set-option rejects it. Plain name is safe because
    # tmux resolves exact matches before prefixes, and we just created it.
    tmux set-option -t "$name" @ccs 1
    created=1
  fi

  if [[ "$action" == "start" ]]; then
    if (( created )); then
      echo "ccs: started '$name' (detached) — attach with: ccs $name"
    else
      echo "ccs: '$name' already running — attach with: ccs $name"
    fi
    return 0
  fi

  tmux attach-session -t "=${name}"

  if tmux has-session -t "=${name}" 2>/dev/null; then
    echo "ccs: '$name' still running (detached) — sleep still disabled"
  else
    (( nosleep )) || _ccs_restore_sleep
  fi
}
