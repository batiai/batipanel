#!/usr/bin/env bash
# batipanel - main entry point
# alias b='bash ~/.batipanel/bin/start.sh'

set -euo pipefail

BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"
source "$BATIPANEL_HOME/lib/common.sh"

show_help() {
  local ver
  ver=$(cat "$BATIPANEL_HOME/VERSION" 2>/dev/null || echo "unknown")
  echo ""
  echo "  batipanel v${ver} - AI workspace manager"
  echo ""
  echo "  b <project>                          Start or resume"
  echo "  b <project> --layout <name>          Start with specific layout"
  echo "  b new <name> [path]                  Register a new project"
  echo "  b reload <project> [--layout <name>] Restart with new layout"
  echo "  b stop <project>                     Stop a session (confirm)"
  echo "  b stop <project> -f                  Stop without confirmation"
  echo "  b ls                                 List sessions & projects"
  echo "  b layouts                            Show available layouts"
  echo "  b config layout [name]               Set default layout"
  echo "  b theme [name]                       Change color theme"
  echo "  b doctor                             Check system health"
  echo "  b server [init|start|stop|status]    AI server (Telegram bot)"
  echo "  b help                               Show this help"
  echo ""
  echo "Options:"
  echo "  --layout, -l <name>   Use a specific layout"
  echo "  --version, -v         Show version"
  echo "  --debug               Enable debug logging"
  echo "  --no-color            Disable colored output"
  echo ""
  echo "Examples:"
  echo "  b myproject"
  echo "  b myproject --layout 6panel"
  echo "  b new myproject ~/project/myproject"
  echo "  b stop myproject"
  echo ""
  tmux_list
}

# parse arguments
LAYOUT_ARG=""
FORCE_FLAG=""
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --layout|-l)
      if [[ $# -lt 2 ]]; then
        echo -e "${RED}--layout requires a layout name${NC}"; exit 1
      fi
      LAYOUT_ARG="$2"
      shift 2
      ;;
    --version|-v)
      echo "batipanel $(cat "$BATIPANEL_HOME/VERSION" 2>/dev/null || echo 'unknown')"
      exit 0
      ;;
    --debug)
      export BATIPANEL_DEBUG=1
      shift
      ;;
    --no-color)
      export BATIPANEL_NO_COLOR=1
      RED='' GREEN='' YELLOW='' BLUE='' NC=''
      shift
      ;;
    -f)
      FORCE_FLAG="-f"
      shift
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

case "${ARGS[0]:-}" in
  new)
    tmux_new "${ARGS[1]:-}" "${ARGS[2]:-}"
    ;;
  reload)
    tmux_stop "${ARGS[1]:-}" "-f"
    sleep 0.3
    tmux_start "${ARGS[1]:-}" "$LAYOUT_ARG"
    ;;
  stop)
    tmux_stop "${ARGS[1]:-}" "$FORCE_FLAG"
    ;;
  ls|list)
    tmux_list
    ;;
  layouts)
    list_layouts
    ;;
  config)
    tmux_config "${ARGS[1]:-}" "${ARGS[2]:-}"
    ;;
  theme)
    tmux_theme "${ARGS[1]:-}"
    ;;
  doctor)
    tmux_doctor
    ;;
  server)
    server_cmd "${ARGS[1]:-}" "${ARGS[2]:-}" "${ARGS[3]:-}"
    ;;
  help)
    show_help
    ;;
  "")
    if is_first_run; then
      run_wizard || show_help
    else
      show_help
    fi
    ;;
  *)
    if [ -f "$BATIPANEL_HOME/projects/${ARGS[0]}.sh" ]; then
      tmux_start "${ARGS[0]}" "$LAYOUT_ARG"
    elif [[ "${ARGS[0]}" =~ ^[a-zA-Z0-9_-]+$ ]] && [ -t 0 ]; then
      # looks like a project name but not registered — offer to create
      _cwd=$(pwd)
      echo -e "Project '${YELLOW}${ARGS[0]}${NC}' is not registered."
      echo ""
      echo -e "  Register ${BLUE}${_cwd}${NC} as '${GREEN}${ARGS[0]}${NC}' and start?"
      printf "  [Y/n]: "
      read -r _answer
      if [[ "${_answer:-Y}" != [nN] ]]; then
        tmux_new "${ARGS[0]}" "$_cwd"
        tmux_start "${ARGS[0]}" "$LAYOUT_ARG"
      fi
    else
      echo -e "${RED}Unknown command: ${ARGS[0]}${NC}"
      echo "  Run 'b help' for usage"
      exit 1
    fi
    ;;
esac
