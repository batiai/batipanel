#!/usr/bin/env bash
# batipanel - 메인 진입점
# alias b='bash ~/.batipanel/bin/start.sh' 로 등록해서 사용

BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"
source "$BATIPANEL_HOME/lib/common.sh"

show_help() {
  echo ""
  echo "  batipanel - AI workspace manager"
  echo ""
  echo "  b <project>                   Start or resume"
  echo "  b <project> --layout <name>  Start with specific layout"
  echo "  b new <name> [path]           Register a new project"
  echo "  b reload <project> [--layout] Restart with new layout"
  echo "  b stop <project>              Stop a session"
  echo "  b ls                          List sessions & projects"
  echo "  b layouts                     Show available layouts"
  echo "  b config layout [name]        Set default layout"
  echo ""
  echo "Examples:"
  echo "  b myproject"
  echo "  b myproject --layout 6panel"
  echo "  b new myproject ~/project/myproject"
  echo "  b stop myproject"
  echo ""
  tmux_list
}

# --layout 파싱
LAYOUT_ARG=""
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --layout|-l)
      LAYOUT_ARG="${2:-}"
      shift 2 || { echo -e "${RED}--layout requires a layout name${NC}"; exit 1; }
      ;;
    --version|-v)
      echo "batipanel $(cat "$BATIPANEL_HOME/VERSION" 2>/dev/null || echo 'unknown')"
      exit 0
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
    tmux_stop "${ARGS[1]:-}"
    sleep 0.3
    tmux_start "${ARGS[1]:-}" "$LAYOUT_ARG"
    ;;
  stop)
    tmux_stop "${ARGS[1]:-}"
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
  help|"")
    show_help
    ;;
  *)
    if [ -f "$BATIPANEL_HOME/projects/${ARGS[0]}.sh" ]; then
      tmux_start "${ARGS[0]}" "$LAYOUT_ARG"
    else
      echo -e "${RED}Unknown command: ${ARGS[0]}${NC}"
      echo "  Run 'b help' for usage"
      exit 1
    fi
    ;;
esac
