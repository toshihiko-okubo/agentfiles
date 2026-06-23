#!/bin/sh
set -eu

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_file() {
  [ -f "$1" ] || fail "missing file: $1"
}

assert_contains() {
  file=$1
  pattern=$2
  grep -Fq "$pattern" "$file" || fail "$file does not contain: $pattern"
}

assert_executable_target() {
  case "$1" in
    */executable_*) ;;
    *) fail "chezmoi executable target must use executable_ prefix: $1" ;;
  esac
}

CLAUDE_HOOK="dot_claude/hooks/executable_notify-agent-attention.sh"
CODEX_HOOK="dot_codex/hooks/executable_notify-agent-attention.sh"
CODEX_HOOKS_JSON="dot_codex/hooks.json"
CLAUDE_INSTALLER="dot_claude/run_onchange_install-notification-hooks.sh.tmpl"

assert_file "$CLAUDE_HOOK"
assert_file "$CODEX_HOOK"
assert_file "$CODEX_HOOKS_JSON"
assert_file "$CLAUDE_INSTALLER"

assert_executable_target "$CLAUDE_HOOK"
assert_executable_target "$CODEX_HOOK"

assert_contains "$CLAUDE_HOOK" "Ping.aiff"
assert_contains "$CLAUDE_HOOK" "Windows Unlock.wav"
assert_contains "$CLAUDE_HOOK" "message-new-instant.oga"
assert_contains "$CLAUDE_HOOK" "printf '\\a'"

assert_contains "$CODEX_HOOK" "Glass.aiff"
assert_contains "$CODEX_HOOK" "Windows Proximity Notification.wav"
assert_contains "$CODEX_HOOK" "complete.oga"
assert_contains "$CODEX_HOOK" "printf '\\a'"

if cmp -s "$CLAUDE_HOOK" "$CODEX_HOOK"; then
  fail "Claude and Codex hook scripts must use different notification sounds"
fi

assert_contains "$CODEX_HOOKS_JSON" '"PermissionRequest"'
assert_contains "$CODEX_HOOKS_JSON" '"Stop"'
assert_contains "$CODEX_HOOKS_JSON" ".codex/hooks/notify-agent-attention.sh"

assert_contains "$CLAUDE_INSTALLER" '"Notification"'
assert_contains "$CLAUDE_INSTALLER" '"permission_prompt"'
assert_contains "$CLAUDE_INSTALLER" '"Stop"'
assert_contains "$CLAUDE_INSTALLER" '"TaskCompleted"'
assert_contains "$CLAUDE_INSTALLER" ".claude/hooks/notify-agent-attention.sh"

sh -n "$CLAUDE_HOOK"
sh -n "$CODEX_HOOK"
sh -n "$CLAUDE_INSTALLER"
