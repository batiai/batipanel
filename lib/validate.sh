#!/usr/bin/env bash
# batipanel validation - tmux version, terminal size, input validation

# tmux version check (2.6+ required)
check_tmux_version() {
  if ! command -v tmux &>/dev/null; then
    echo -e "${RED}tmux is not installed${NC}"
    case "$(uname -s)" in
      Darwin) echo "  Install: brew install tmux" ;;
      Linux)
        if command -v apt-get &>/dev/null; then
          echo "  Install: sudo apt-get install tmux"
        elif command -v dnf &>/dev/null; then
          echo "  Install: sudo dnf install tmux"
        elif command -v pacman &>/dev/null; then
          echo "  Install: sudo pacman -S tmux"
        else
          echo "  Install tmux using your package manager"
        fi
        ;;
      *) echo "  Install tmux for your OS" ;;
    esac
    return 1
  fi

  local ver
  ver=$(tmux -V | grep -oE '[0-9]+\.[0-9]+' | head -1)
  if [[ -z "$ver" ]]; then
    debug_log "Could not parse tmux version, continuing anyway"
    return 0
  fi

  local major minor
  major="${ver%%.*}"
  minor="${ver#*.}"
  if (( major < 2 || (major == 2 && minor < 6) )); then
    echo -e "${RED}tmux $ver is too old (2.6+ required)${NC}"
    case "$(uname -s)" in
      Darwin) echo "  Upgrade: brew install tmux" ;;
      *)
        if command -v apt-get &>/dev/null; then
          echo "  Upgrade: sudo apt-get install --only-upgrade tmux"
        elif command -v dnf &>/dev/null; then
          echo "  Upgrade: sudo dnf upgrade tmux"
        else
          echo "  Upgrade tmux using your package manager"
        fi
        ;;
    esac
    return 1
  fi
  debug_log "tmux version $ver OK"
}

# terminal size check (warning only, never blocks)
check_terminal_size() {
  local layout="${1:-$DEFAULT_LAYOUT}"
  local cols lines
  cols=$(tput cols 2>/dev/null || echo 0)
  lines=$(tput lines 2>/dev/null || echo 0)

  debug_log "Terminal size: ${cols}x${lines}, layout: $layout"

  if (( cols == 0 || lines == 0 )); then
    return 0
  fi

  local min_cols=120 min_lines=30
  case "$layout" in
    4panel|5panel)  min_cols=100; min_lines=24 ;;
    6panel)         min_cols=140; min_lines=35 ;;
    7panel*|8panel) min_cols=160; min_lines=40 ;;
    dual-claude)    min_cols=200; min_lines=40 ;;
    devops)         min_cols=140; min_lines=35 ;;
  esac

  if (( cols < min_cols || lines < min_lines )); then
    echo -e "${YELLOW}Warning: Terminal ${cols}x${lines} may be small for '$layout' (recommend ${min_cols}x${min_lines})${NC}"
    if [[ "$layout" != "4panel" ]]; then
      echo -e "${YELLOW}  Tip: try 'b <project> --layout 4panel' for smaller terminals${NC}"
    fi
  fi
}

# session name validation
validate_session_name() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo -e "${RED}Session name is required${NC}"
    return 1
  fi
  if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo -e "${RED}Session name may only contain letters, numbers, _ and -: $name${NC}"
    return 1
  fi
}
