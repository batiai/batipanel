#!/usr/bin/env bats
# tests for server modules - unit tests (no Docker required)

load test_helper

setup() {
  setup_batipanel_env
  load_batipanel_modules
  source "$BATIPANEL_HOME/lib/themes-data.sh"
  source "$BATIPANEL_HOME/lib/themes-tmux.sh"
  source "$BATIPANEL_HOME/lib/themes-bash.sh"
  source "$BATIPANEL_HOME/lib/themes.sh"
  source "$BATIPANEL_HOME/lib/layout.sh"
  source "$BATIPANEL_HOME/lib/session.sh"
  source "$BATIPANEL_HOME/lib/project.sh"
  source "$BATIPANEL_HOME/lib/server-docker.sh"
  source "$BATIPANEL_HOME/lib/server.sh"
  source "$BATIPANEL_HOME/lib/server-init.sh"
}

teardown() {
  teardown_batipanel_env
}

# === BATIPANEL_DOCKER_DIR ===

@test "BATIPANEL_DOCKER_DIR is defined" {
  [ -n "$BATIPANEL_DOCKER_DIR" ]
}

@test "BATIPANEL_DOCKER_DIR points to docker directory" {
  [[ "$BATIPANEL_DOCKER_DIR" == *"/docker" ]]
}

@test "BATIPANEL_SERVER_DIR is defined" {
  [ -n "$BATIPANEL_SERVER_DIR" ]
}

# === server_status without config ===

@test "server_status shows not configured when no .env" {
  rm -f "$BATIPANEL_SERVER_DIR/.env"
  run server_status
  [ "$status" -eq 0 ]
  [[ "$output" == *"Not configured"* ]]
}

# === server_config_cmd ===

@test "server_config_cmd shows not configured without .env" {
  rm -f "$BATIPANEL_SERVER_DIR/.env"
  run server_config_cmd
  [[ "$output" == *"Not configured"* ]]
}

@test "server_config_cmd masks sensitive values" {
  mkdir -p "$BATIPANEL_SERVER_DIR"
  cat > "$BATIPANEL_SERVER_DIR/.env" << 'EOF'
TELEGRAM_BOT_TOKEN=123456:ABC
ANTHROPIC_API_KEY=sk-ant-xxx
OPENCLAW_GATEWAY_TOKEN=secret123
OPENCLAW_SANDBOX=1
EOF
  run server_config_cmd
  [[ "$output" == *"****"* ]]
  # should NOT expose actual token
  [[ "$output" != *"123456:ABC"* ]]
  [[ "$output" != *"sk-ant-xxx"* ]]
  # non-sensitive values should show
  [[ "$output" == *"OPENCLAW_SANDBOX=1"* ]]
}

# === server_start without config ===

@test "server_start fails without .env" {
  rm -f "$BATIPANEL_SERVER_DIR/.env"
  run server_start
  [ "$status" -eq 1 ]
  [[ "$output" == *"not configured"* || "$output" == *"Not configured"* || "$output" == *"server init"* ]]
}

# === server_cmd router ===

@test "server_cmd shows help with no subcommand" {
  run server_cmd ""
  [ "$status" -eq 0 ]
  [[ "$output" == *"server init"* ]]
  [[ "$output" == *"server start"* ]]
  [[ "$output" == *"server stop"* ]]
}
