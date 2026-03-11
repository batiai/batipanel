#!/usr/bin/env bash
# batipanel project - registration and configuration

tmux_new() {
  local SESSION="$1"
  local PROJECT_PATH="${2:-$(pwd)}"

  if [ -z "$SESSION" ]; then
    echo "Usage: b new <name> [project-path]"
    return 1
  fi

  validate_session_name "$SESSION" || return 1

  # resolve to absolute path
  if [[ "$PROJECT_PATH" != /* ]]; then
    local original_path="$PROJECT_PATH"
    PROJECT_PATH="$(cd "$PROJECT_PATH" 2>/dev/null && pwd)" || {
      echo -e "${RED}Path not found: $original_path${NC}"
      return 1
    }
  fi

  if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}Directory does not exist: $PROJECT_PATH${NC}"
    return 1
  fi

  mkdir -p "$BATIPANEL_HOME/projects"

  # Generate project script — escape path safely to avoid injection
  local safe_path
  safe_path=$(printf '%q' "$PROJECT_PATH")
  debug_log "tmux_new: session=$SESSION path=$safe_path"

  cat > "$BATIPANEL_HOME/projects/${SESSION}.sh" <<TMUXEOF
#!/usr/bin/env bash
SESSION="\${1:-${SESSION}}"
PROJECT=${safe_path}
BATIPANEL_HOME="\${BATIPANEL_HOME:-\$HOME/.batipanel}"
source "\$BATIPANEL_HOME/lib/common.sh"
load_layout "\$SESSION" "\$PROJECT" "\${LAYOUT:-}"
TMUXEOF
  chmod +x "$BATIPANEL_HOME/projects/${SESSION}.sh"

  echo -e "${GREEN}Project created: ${SESSION}${NC}"
  echo -e "${YELLOW}Start now: b ${SESSION}${NC}"
}

tmux_config() {
  local key="${1:-}"
  local value="${2:-}"

  case "$key" in
    layout)
      if [ -z "$value" ]; then
        echo -e "Current default layout: ${GREEN}$DEFAULT_LAYOUT${NC}"
        echo ""
        list_layouts
        return
      fi
      if ! [[ "$value" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}Invalid layout name: $value${NC}"
        return 1
      fi
      if [ ! -f "$BATIPANEL_HOME/layouts/${value}.sh" ]; then
        echo -e "${RED}Layout not found: $value${NC}"
        list_layouts
        return 1
      fi
      # update config.sh
      if [ -f "$TMUX_CONFIG" ]; then
        if grep -q "DEFAULT_LAYOUT=" "$TMUX_CONFIG"; then
          _sed_i "s|DEFAULT_LAYOUT=.*|DEFAULT_LAYOUT=\"$value\"|" "$TMUX_CONFIG"
        else
          echo "DEFAULT_LAYOUT=\"$value\"" >> "$TMUX_CONFIG"
        fi
      else
        echo "DEFAULT_LAYOUT=\"$value\"" > "$TMUX_CONFIG"
      fi
      echo -e "${GREEN}Default layout changed: $value${NC}"
      ;;
    theme)
      tmux_theme "$value"
      ;;
    iterm-cc)
      if [ -z "$value" ]; then
        echo -e "  iTerm2 -CC mode: ${GREEN}${BATIPANEL_ITERM_CC:-not set}${NC}"
        echo ""
        echo "  b config iterm-cc on    Enable iTerm2 native integration"
        echo "  b config iterm-cc off   Use standard tmux UI (themed)"
        return
      fi
      case "$value" in
        on|1)
          _save_config "BATIPANEL_ITERM_CC" "1"
          BATIPANEL_ITERM_CC="1"
          echo -e "${GREEN}iTerm2 -CC mode enabled${NC}"
          echo "  Next session will use native iTerm2 splits."
          ;;
        off|0)
          _save_config "BATIPANEL_ITERM_CC" "0"
          BATIPANEL_ITERM_CC="0"
          echo -e "${GREEN}iTerm2 -CC mode disabled${NC}"
          echo "  Next session will use standard tmux UI with themes."
          ;;
        *)
          echo -e "${RED}Invalid value: $value (use on/off)${NC}"
          ;;
      esac
      ;;
    "")
      echo "Usage: b config <key> [value]"
      echo ""
      echo "  b config layout          Show current default layout"
      echo "  b config layout 7panel   Change default layout"
      echo "  b config theme           Show current theme"
      echo "  b config theme dracula   Change color theme"
      echo "  b config iterm-cc        iTerm2 native integration (on/off)"
      ;;
    *)
      echo -e "${RED}Unknown config key: $key${NC}"
      ;;
  esac
}
