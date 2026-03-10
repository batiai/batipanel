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
