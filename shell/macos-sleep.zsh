# macOS sleep control via pmset.

# Keep the Mac awake (lid close, idle, everything) until re-enabled.
sleep-disabled() {
  sudo pmset -b disablesleep 1 && echo "sleep DISABLED — Mac stays awake"
}

# Restore the normal sleep behaviour.
sleep-enabled() {
  sudo pmset -b disablesleep 0 && echo "sleep ENABLED — normal sleep restored"
}

# Report the current setting without touching it.
sleep-status() {
  local state
  state=$(pmset -g | awk '/SleepDisabled/ {print $2}')
  case "$state" in
    1) echo "sleep DISABLED (Mac stays awake)" ;;
    0|"") echo "sleep ENABLED (normal sleep)" ;;
    *) echo "SleepDisabled = $state" ;;
  esac
}

sleep-help() {
  cat <<'EOF'
sleep-disabled   # ON  -> sleep disabled (Mac stays awake)
sleep-enabled    # OFF -> normal sleep restored
sleep-status     #     -> show which one is active right now
EOF
}
