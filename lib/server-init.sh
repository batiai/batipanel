#!/usr/bin/env bash
# batipanel server-init - interactive setup wizard for AI server

# === b server init ===
server_init() {
  echo ""
  echo -e "${BLUE}=== Batipanel Server Setup ===${NC}"
  echo ""
  echo "  AI assistant accessible via Telegram."
  echo "  Powered by OpenClaw, secured by Docker."
  echo ""

  _require_docker || return 1

  # warn if existing configuration found
  if [ -f "$BATIPANEL_SERVER_DIR/.env" ] && [ -t 0 ]; then
    echo -e "  ${YELLOW}Existing configuration found.${NC}"
    printf "  Overwrite and reconfigure? [y/N]: "
    local overwrite
    read -r overwrite
    if [[ ! "$overwrite" =~ ^[Yy] ]]; then
      echo "  Cancelled. Current configuration preserved."
      return 0
    fi
    echo ""
  fi

  # create server directory
  mkdir -p "$BATIPANEL_SERVER_DIR"/{config,workspace}

  # --- Step 1: Telegram Bot Token ---
  echo -e "${GREEN}Step 1/3: Telegram Bot${NC}"
  echo ""
  echo "  Create a bot via Telegram @BotFather:"
  echo "    1. Open Telegram, search @BotFather"
  echo "    2. Send /newbot"
  echo "    3. Choose a name and username"
  echo "    4. Copy the token below"
  echo ""
  printf "  Bot Token: "
  local bot_token
  read -r bot_token

  if [[ -z "$bot_token" || ! "$bot_token" =~ ^[0-9]+:.+$ ]]; then
    echo -e "${RED}  Invalid token format. Expected: 123456789:ABCDEF...${NC}"
    return 1
  fi
  echo -e "  ${GREEN}✓${NC} Token format valid"

  # --- Step 2: AI Model ---
  echo ""
  echo -e "${GREEN}Step 2/3: AI Model${NC}"
  echo ""
  local ai_config=""
  local use_max="n"

  # check if claude CLI is authenticated
  if has_cmd claude; then
    printf "  Use Claude Max subscription (no API cost)? [Y/n]: "
    read -r use_max
    use_max="${use_max:-Y}"
  fi

  if [[ "$use_max" =~ ^[Yy] ]]; then
    local session_key=""
    local claude_config="$HOME/.claude/config.json"
    if [ -f "$claude_config" ]; then
      session_key=$(grep -o '"sessionKey"[[:space:]]*:[[:space:]]*"[^"]*"' "$claude_config" 2>/dev/null \
        | head -1 | sed 's/.*"sessionKey"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)
    fi

    if [ -n "$session_key" ]; then
      ai_config="CLAUDE_AI_SESSION_KEY=${session_key}"
      echo -e "  ${GREEN}✓${NC} Claude Max session detected (no API cost)"
    else
      echo -e "  ${YELLOW}⚠${NC} Could not detect Claude session key"
      echo "  Falling back to API key mode."
      use_max="n"
    fi
  fi

  if [[ ! "$use_max" =~ ^[Yy] ]]; then
    echo ""
    printf "  Anthropic API Key (sk-ant-...): "
    local api_key
    read -r api_key
    if [[ -z "$api_key" ]]; then
      echo -e "${RED}  API key is required.${NC}"
      return 1
    fi
    ai_config="ANTHROPIC_API_KEY=${api_key}"
    echo -e "  ${GREEN}✓${NC} API key configured (usage-based billing)"
  fi

  # --- Step 3: Security ---
  echo ""
  echo -e "${GREEN}Step 3/3: Security${NC}"
  echo ""
  echo "  Your Telegram user ID (numeric)."
  echo "  Find it: message @userinfobot on Telegram, send /start"
  echo ""
  printf "  Telegram User ID: "
  local user_id
  read -r user_id

  if [[ ! "$user_id" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}  Invalid user ID. Must be numeric.${NC}"
    return 1
  fi
  echo -e "  ${GREEN}✓${NC} Only user $user_id can access the bot"

  # --- Generate config files ---
  _generate_server_config "$bot_token" "$ai_config" "$user_id"
}

# Generate all server configuration files
_generate_server_config() {
  local bot_token="$1"
  local ai_config="$2"
  local user_id="$3"

  echo ""
  echo "Generating configuration..."

  # generate gateway token
  local gw_token
  if has_cmd openssl; then
    gw_token=$(openssl rand -hex 32)
  else
    gw_token=$(head -c 32 /dev/urandom | xxd -p 2>/dev/null \
      || date +%s%N | sha256sum | head -c 64)
  fi

  # .env file
  local env_file="$BATIPANEL_SERVER_DIR/.env"
  cat > "$env_file" << EOF
# batipanel server - auto-generated $(date +%Y-%m-%d)
TELEGRAM_BOT_TOKEN=${bot_token}
${ai_config}
OPENCLAW_GATEWAY_TOKEN=${gw_token}
OPENCLAW_GATEWAY_BIND=loopback
OPENCLAW_SANDBOX=1
EOF
  chmod 600 "$env_file"
  echo -e "  ${GREEN}✓${NC} Environment configured"

  # openclaw.json
  local oc_config="$BATIPANEL_SERVER_DIR/config/openclaw.json"
  cat > "$oc_config" << EOF
{
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "allowlist",
      "allowFrom": [${user_id}],
      "groups": {}
    }
  },
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "non-main",
        "scope": "agent",
        "workspaceAccess": "none"
      }
    }
  },
  "gateway": {
    "auth": {
      "token": "${gw_token}"
    }
  }
}
EOF
  echo -e "  ${GREEN}✓${NC} OpenClaw configured"

  # docker-compose.yml
  cp "$BATIPANEL_DOCKER_DIR/docker-compose.yml" \
    "$BATIPANEL_SERVER_DIR/docker-compose.yml"
  echo -e "  ${GREEN}✓${NC} Docker Compose ready"

  # done
  echo ""
  echo -e "${GREEN}=== Setup Complete ===${NC}"
  echo ""
  echo "  Start the server:"
  echo "    b server start"
  echo ""
  echo "  Your bot: search for it on Telegram and send a message!"
  echo ""
}
