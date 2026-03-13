#!/usr/bin/env bats
# tests for lib/validate.sh - input validation

load test_helper

setup() {
  setup_batipanel_env
  load_batipanel_modules
}

teardown() {
  teardown_batipanel_env
}

# === validate_session_name ===

@test "validate_session_name accepts alphanumeric" {
  run validate_session_name "myproject"
  [ "$status" -eq 0 ]
}

@test "validate_session_name accepts underscores and dashes" {
  run validate_session_name "my-project_1"
  [ "$status" -eq 0 ]
}

@test "validate_session_name rejects empty" {
  run validate_session_name ""
  [ "$status" -eq 1 ]
}

@test "validate_session_name rejects spaces" {
  run validate_session_name "my project"
  [ "$status" -eq 1 ]
}

@test "validate_session_name rejects special characters" {
  run validate_session_name "proj;rm -rf"
  [ "$status" -eq 1 ]
}

@test "validate_session_name rejects dots" {
  run validate_session_name "proj.name"
  [ "$status" -eq 1 ]
}

@test "validate_session_name rejects path traversal" {
  run validate_session_name "../etc/passwd"
  [ "$status" -eq 1 ]
}

# === check_tmux_version ===

@test "check_tmux_version succeeds when tmux is available" {
  if ! command -v tmux &>/dev/null; then
    skip "tmux not installed"
  fi
  run check_tmux_version
  [ "$status" -eq 0 ]
}
