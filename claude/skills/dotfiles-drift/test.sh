#!/usr/bin/env bash
# Test check-drift.py against fabricated clean and drifted fixtures.
set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")" && pwd)/check-drift.py"
S="$(mktemp -d)"
trap 'rm -rf "$S"' EXIT
rm -rf "$S"

make_fixture() { # $1=name $2=live_settings $3=template_settings $4=plugins_txt $5=live_plugins_json_fragment
    local root="$S/$1"
    mkdir -p "$root/dotfiles/claude" "$root/claude" "$root/cursor-home"
    printf '%s' "$2" > "$root/claude/settings.json"
    printf '%s' "$3" > "$root/dotfiles/claude/settings.json"
    printf '%s\n' "$4" > "$root/dotfiles/claude/plugins.txt"
    # identical mcp.json on both sides except env token values
    printf '{"mcpServers":{"gh":{"command":"npx","env":{"TOKEN":"real-secret"}},"GitKraken":{"command":"gk"}}}' > "$root/cursor-home/mcp.json"
    mkdir -p "$root/dotfiles/cursor"
    printf '{"mcpServers":{"gh":{"command":"npx","env":{"TOKEN":"<placeholder>"}}}}' > "$root/dotfiles/cursor/mcp.json"
}

CLEAN_LIVE='{"model":"claude-x[1m]","effortLevel":"high","enabledPlugins":{"a@m":true,"b@m":true},"mcpServers":{"ruff":{"command":"uvx"},"snyk":{"command":"snyk"}}}'
CLEAN_TPL='{"effortLevel":"high","enabledPlugins":{"a@m":true,"b@m":true},"mcpServers":{"ruff":{"command":"uvx"}}}'
make_fixture clean "$CLEAN_LIVE" "$CLEAN_TPL" "a@m
b@m"

DRIFT_LIVE='{"model":"claude-x[1m]","effortLevel":"medium","voiceEnabled":true,"enabledPlugins":{"a@m":true},"mcpServers":{"ruff":{"command":"uvx"},"legacy":{"command":"npx"}}}'
make_fixture drift "$DRIFT_LIVE" "$CLEAN_TPL" "a@m
b@m"

run() { # $1=fixture; prints exit code, captures output
    local root="$S/$1"
    OUT="$(DOTFILES="$root/dotfiles" CLAUDE_DIR="$root/claude" CURSOR_HOME="$root/cursor-home" SKIP_GIT_CHECK=1 \
        python3 "$SCRIPT" 2>&1)" && RC=0 || RC=$?
}

fail() { echo "FAIL: $1"; echo "--- output ---"; echo "$OUT"; exit 1; }

run clean
[ "$RC" -eq 0 ] || fail "clean fixture should exit 0 (got $RC)"

run drift
[ "$RC" -eq 1 ] || fail "drift fixture should exit 1 (got $RC)"
echo "$OUT" | grep -q "effortLevel" || fail "should report effortLevel value drift"
echo "$OUT" | grep -q "voiceEnabled" || fail "should report live-only key voiceEnabled"
echo "$OUT" | grep -q "legacy" || fail "should report live-only mcp server legacy"
echo "$OUT" | grep -q "b@m" || fail "should report plugin b@m in plugins.txt but not enabled"
echo "$OUT" | grep -q "real-secret" && fail "must never print secret values"
echo "$OUT" | grep -q "GitKraken" && fail "editor-managed GitKraken entry must be ignored"

echo "all check-drift tests passed"
