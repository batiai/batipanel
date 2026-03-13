#!/usr/bin/env bats
# tests for lib/core.sh - colors, utilities, config loading

load test_helper

setup() {
  setup_batipanel_env
  load_batipanel_modules
}

teardown() {
  teardown_batipanel_env
}

# === has_cmd ===

@test "has_cmd returns 0 for existing command" {
  run has_cmd bash
  [ "$status" -eq 0 ]
}

@test "has_cmd returns 1 for missing command" {
  run has_cmd nonexistent_cmd_xyz_123
  [ "$status" -eq 1 ]
}

# === _sed_i ===

@test "_sed_i works on a file" {
  local tmpfile="$BATIPANEL_HOME/test_sed.txt"
  echo "hello world" > "$tmpfile"
  _sed_i 's/world/earth/' "$tmpfile"
  [ "$(cat "$tmpfile")" = "hello earth" ]
}

# === colors ===

@test "NO_COLOR disables color variables" {
  export NO_COLOR=1
  source "$BATIPANEL_HOME/lib/core.sh"
  [ -z "$RED" ]
  [ -z "$GREEN" ]
  [ -z "$YELLOW" ]
  [ -z "$BLUE" ]
  [ -z "$NC" ]
}

# === debug_log ===

@test "debug_log is silent when BATIPANEL_DEBUG=0" {
  BATIPANEL_DEBUG=0
  run debug_log "test message"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "debug_log outputs when BATIPANEL_DEBUG=1" {
  BATIPANEL_DEBUG=1
  run debug_log "test message"
  [ "$status" -eq 0 ]
}

# === config loading ===

@test "config loads DEFAULT_LAYOUT from config.sh" {
  echo 'DEFAULT_LAYOUT="5panel"' > "$BATIPANEL_HOME/config.sh"
  source "$BATIPANEL_HOME/lib/core.sh"
  [ "$DEFAULT_LAYOUT" = "5panel" ]
}

@test "config rejects invalid layout names" {
  echo 'DEFAULT_LAYOUT="../evil"' > "$BATIPANEL_HOME/config.sh"
  source "$BATIPANEL_HOME/lib/core.sh"
  [ "$DEFAULT_LAYOUT" = "7panel" ]
}

@test "config loads BATIPANEL_THEME" {
  echo 'BATIPANEL_THEME="dracula"' > "$BATIPANEL_HOME/config.sh"
  source "$BATIPANEL_HOME/lib/core.sh"
  [ "$BATIPANEL_THEME" = "dracula" ]
}

@test "config rejects unknown keys" {
  echo 'EVIL_KEY="something"' > "$BATIPANEL_HOME/config.sh"
  source "$BATIPANEL_HOME/lib/core.sh"
  # EVIL_KEY should not be set by the config parser
  [ -z "${EVIL_KEY:-}" ]
}

@test "config handles quoted values" {
  echo "DEFAULT_LAYOUT='6panel'" > "$BATIPANEL_HOME/config.sh"
  source "$BATIPANEL_HOME/lib/core.sh"
  [ "$DEFAULT_LAYOUT" = "6panel" ]
}

@test "_save_config creates new config file" {
  rm -f "$BATIPANEL_HOME/config.sh"
  _save_config "DEFAULT_LAYOUT" "8panel"
  [ -f "$BATIPANEL_HOME/config.sh" ]
  grep -q 'DEFAULT_LAYOUT="8panel"' "$BATIPANEL_HOME/config.sh"
}

@test "_save_config updates existing key" {
  echo 'DEFAULT_LAYOUT="5panel"' > "$BATIPANEL_HOME/config.sh"
  _save_config "DEFAULT_LAYOUT" "6panel"
  grep -q 'DEFAULT_LAYOUT="6panel"' "$BATIPANEL_HOME/config.sh"
  # should not have duplicate
  local count
  count=$(grep -c 'DEFAULT_LAYOUT=' "$BATIPANEL_HOME/config.sh")
  [ "$count" -eq 1 ]
}
