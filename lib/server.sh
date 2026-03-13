#!/usr/bin/env bash
# batipanel server - Docker-based OpenClaw AI gateway management
# Provides: b server init|start|stop|status|logs|config|update

BATIPANEL_SERVER_DIR="${BATIPANEL_SERVER_DIR:-$BATIPANEL_HOME/server}"
BATIPANEL_DOCKER_DIR="${BATIPANEL_DOCKER_DIR:-$BATIPANEL_HOME/docker}"

# Docker dependency management is in server-docker.sh
# _require_docker(), _install_docker(), _install_compose_plugin()

# indent multiline output by 2 spaces
_indent() { while IFS= read -r line; do printf '  %s\n' "$line"; done <<< "$1"; }

# docker compose command (v2 plugin or standalone)
_compose() {
  if docker compose version &>/dev/null 2>&1; then
    docker compose -f "$BATIPANEL_SERVER_DIR/docker-compose.yml" "$@"
  else
    docker-compose -f "$BATIPANEL_SERVER_DIR/docker-compose.yml" "$@"
  fi
}

_server_is_running() {
  _compose ps --status running 2>/dev/null | grep -q "batipanel-server"
}

# === b server start ===
server_start() {
  _require_docker || return 1

  if [ ! -f "$BATIPANEL_SERVER_DIR/.env" ]; then
    echo -e "${RED}Server not configured. Run 'b server init' first.${NC}"
    return 1
  fi

  # check for port conflict
  local port="${BATIPANEL_GATEWAY_PORT:-18789}"
  if ss -tuln 2>/dev/null | grep -q ":${port} " \
    || netstat -tuln 2>/dev/null | grep -q ":${port} "; then
    echo -e "${RED}Port ${port} is already in use.${NC}"
    echo "  Check what is using it: ss -tuln | grep :${port}"
    echo "  Use a different port:   BATIPANEL_GATEWAY_PORT=18790 b server start"
    return 1
  fi

  log_info "server start"
  echo "Starting batipanel server..."

  local compose_output
  if ! compose_output=$(_compose up -d --pull always 2>&1); then
    _indent "$compose_output"
    echo -e "${RED}Failed to start server${NC}"
    return 1
  fi
  _indent "$compose_output"

  # wait for health
  echo ""
  echo "Waiting for server to be ready..."
  local attempts=0
  while (( attempts < 30 )); do
    if _server_is_running; then
      echo ""
      echo -e "${GREEN}=== Server Running ===${NC}"
      _print_server_info
      return 0
    fi
    sleep 2
    attempts=$((attempts + 1))
    printf "."
  done

  echo ""
  echo -e "${YELLOW}Server is starting but not yet healthy.${NC}"
  echo "  Check logs: b server logs"
}

# === b server stop ===
server_stop() {
  _require_docker || return 1

  if [ ! -f "$BATIPANEL_SERVER_DIR/docker-compose.yml" ]; then
    echo -e "${YELLOW}No server configuration found.${NC}"
    return 1
  fi

  log_info "server stop"
  echo "Stopping batipanel server..."
  local compose_output
  if ! compose_output=$(_compose down 2>&1); then
    _indent "$compose_output"
    echo -e "${RED}Failed to stop server${NC}"
    return 1
  fi
  _indent "$compose_output"
  echo -e "${GREEN}Server stopped.${NC}"
}

# === b server status ===
server_status() {
  echo ""
  echo -e "${BLUE}=== Batipanel Server Status ===${NC}"
  echo ""

  if [ ! -f "$BATIPANEL_SERVER_DIR/.env" ]; then
    echo -e "  ${YELLOW}Not configured. Run 'b server init'${NC}"
    return 0
  fi

  if ! has_cmd docker || ! docker info &>/dev/null 2>&1; then
    echo -e "  ${RED}Docker is not running.${NC}"
    return 1
  fi

  if _server_is_running; then
    echo -e "  Status:   ${GREEN}Running${NC}"
    _print_server_info
    echo ""

    # security report
    echo -e "  ${BLUE}Security${NC}"
    echo -e "  ├─ Container:  Docker isolated"
    if grep -q "OPENCLAW_SANDBOX=1" "$BATIPANEL_SERVER_DIR/.env" 2>/dev/null; then
      echo -e "  ├─ Sandbox:    ${GREEN}enabled${NC}"
    else
      echo -e "  ├─ Sandbox:    ${YELLOW}disabled${NC}"
    fi
    echo -e "  ├─ Network:    loopback only"
    echo -e "  ├─ Access:     allowlist"
    echo -e "  └─ API Keys:   $(stat -c '%a' "$BATIPANEL_SERVER_DIR/.env" 2>/dev/null || stat -f '%Lp' "$BATIPANEL_SERVER_DIR/.env" 2>/dev/null) permissions"
  else
    echo -e "  Status:   ${RED}Stopped${NC}"
    echo ""
    echo "  Start with: b server start"
  fi
  echo ""
}

# === b server logs ===
server_logs() {
  _require_docker || return 1

  if [ ! -f "$BATIPANEL_SERVER_DIR/docker-compose.yml" ]; then
    echo -e "${YELLOW}No server configuration found.${NC}"
    return 1
  fi

  local follow="${1:-}"
  if [[ "$follow" == "-f" ]]; then
    _compose logs -f --tail 50
  else
    _compose logs --tail 100
  fi
}

# === b server update ===
server_update() {
  _require_docker || return 1

  if [ ! -f "$BATIPANEL_SERVER_DIR/.env" ]; then
    echo -e "${RED}Server not configured.${NC}"
    return 1
  fi

  log_info "server update"
  echo "Updating batipanel server..."
  local compose_output
  if ! compose_output=$(_compose pull 2>&1); then
    _indent "$compose_output"
    echo -e "${RED}Failed to pull server image${NC}"
    return 1
  fi
  _indent "$compose_output"

  echo "Restarting with new image..."
  if ! compose_output=$(_compose up -d 2>&1); then
    _indent "$compose_output"
    echo -e "${RED}Failed to restart server${NC}"
    return 1
  fi
  _indent "$compose_output"

  echo -e "${GREEN}Server updated.${NC}"
}

# === b server config ===
server_config_cmd() {
  local key="${1:-}"

  if [ -z "$key" ]; then
    echo -e "${BLUE}=== Server Configuration ===${NC}"
    echo ""
    if [ -f "$BATIPANEL_SERVER_DIR/.env" ]; then
      echo "  Environment: $BATIPANEL_SERVER_DIR/.env"
      # show config without sensitive values
      while IFS='=' read -r k v; do
        [[ "$k" =~ ^#.*$ || -z "$k" ]] && continue
        case "$k" in
          *TOKEN*|*KEY*|*SECRET*)
            echo "  $k=****"
            ;;
          *)
            echo "  $k=$v"
            ;;
        esac
      done < "$BATIPANEL_SERVER_DIR/.env"
    else
      echo "  Not configured. Run 'b server init'"
    fi
    echo ""
    return 0
  fi

  echo -e "${YELLOW}Direct config editing not yet supported.${NC}"
  echo "  Edit manually: $BATIPANEL_SERVER_DIR/.env"
  echo "  Then restart:  b server stop && b server start"
}

# === helpers ===
_print_server_info() {
  local model="unknown"
  if grep -q "CLAUDE_AI_SESSION_KEY" "$BATIPANEL_SERVER_DIR/.env" 2>/dev/null; then
    model="Claude Opus 4.6 (Max — no API cost)"
  elif grep -q "ANTHROPIC_API_KEY" "$BATIPANEL_SERVER_DIR/.env" 2>/dev/null; then
    model="Claude (API key — usage billing)"
  fi

  local telegram="not configured"
  if grep -q "TELEGRAM_BOT_TOKEN" "$BATIPANEL_SERVER_DIR/.env" 2>/dev/null; then
    telegram="connected"
  fi

  echo -e "  AI Model: ${GREEN}${model}${NC}"
  echo -e "  Telegram: ${GREEN}${telegram}${NC}"
}

# === Router ===
server_cmd() {
  local subcmd="${1:-}"
  shift 2>/dev/null || true

  case "$subcmd" in
    init)
      server_init
      ;;
    start)
      server_start
      ;;
    stop)
      server_stop
      ;;
    status)
      server_status
      ;;
    logs)
      server_logs "$@"
      ;;
    update)
      server_update
      ;;
    config)
      server_config_cmd "$@"
      ;;
    *)
      echo -e "${BLUE}=== Batipanel Server ===${NC}"
      echo ""
      echo "  b server init              Setup Telegram AI bot"
      echo "  b server start             Start the server"
      echo "  b server stop              Stop the server"
      echo "  b server status            Show server status"
      echo "  b server logs [-f]         View logs (follow with -f)"
      echo "  b server update            Pull latest image & restart"
      echo "  b server config            View configuration"
      echo ""
      ;;
  esac
}
