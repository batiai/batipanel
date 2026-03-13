#!/usr/bin/env bats
# tests for lib/logger.sh - structured logging

load test_helper

setup() {
  setup_batipanel_env
  load_batipanel_modules
}

teardown() {
  teardown_batipanel_env
}

@test "log_info writes to log file" {
  log_info "test info message"
  [ -f "$BATIPANEL_LOG_FILE" ]
  grep -q "INFO" "$BATIPANEL_LOG_FILE"
  grep -q "test info message" "$BATIPANEL_LOG_FILE"
}

@test "log_warn writes WARN level" {
  log_warn "test warning"
  grep -q "WARN" "$BATIPANEL_LOG_FILE"
}

@test "log_error writes ERROR level" {
  log_error "test error"
  grep -q "ERROR" "$BATIPANEL_LOG_FILE"
}

@test "log entries have timestamps" {
  log_info "timestamp test"
  # ISO 8601 format: 2026-03-13T...
  grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$BATIPANEL_LOG_FILE"
}

@test "debug messages filtered when level is info" {
  BATIPANEL_LOG_LEVEL="info"
  log_debug "should not appear"
  if [ -f "$BATIPANEL_LOG_FILE" ]; then
    ! grep -q "should not appear" "$BATIPANEL_LOG_FILE"
  fi
}

@test "debug messages appear when level is debug" {
  BATIPANEL_LOG_LEVEL="debug"
  log_debug "should appear"
  grep -q "should appear" "$BATIPANEL_LOG_FILE"
}

@test "log_rotate creates rotated file when log exceeds 5MB" {
  # create a >5MB file
  dd if=/dev/zero bs=1024 count=5200 2>/dev/null | tr '\0' 'A' > "$BATIPANEL_LOG_FILE"
  log_rotate
  # original file should be gone or recreated small
  local rotated_count
  rotated_count=$(find "$BATIPANEL_LOG_DIR" -name "batipanel.log.*" | wc -l)
  [ "$rotated_count" -ge 1 ]
}

@test "log directory created automatically" {
  rm -rf "$BATIPANEL_LOG_DIR"
  log_info "auto create test"
  [ -d "$BATIPANEL_LOG_DIR" ]
}
