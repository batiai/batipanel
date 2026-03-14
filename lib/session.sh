#!/usr/bin/env bash
# batipanel session - start, stop, list, project listing

# portable timeout: timeout → gtimeout → perl fallback
_tmux_timeout() {
  local secs="$1"; shift
  if command -v timeout &>/dev/null; then
    timeout "$secs" "$@"
  elif command -v gtimeout &>/dev/null; then
    gtimeout "$secs" "$@"
  else
    # perl is always available on macOS/Linux
    perl -e "alarm $secs; exec @ARGV" -- "$@"
  fi
}

tmux_start() {
  local SESSION="$1"
  local LAYOUT="${2:-}"
  local SCRIPT="$BATIPANEL_HOME/projects/${SESSION}.sh"

  validate_session_name "$SESSION" || return 1

  if [ ! -f "$SCRIPT" ]; then
    echo -e "${RED}Project not found: ${SESSION}${NC}"
    echo -e "${YELLOW}Available projects:${NC}"
    list_projects
    return 1
  fi

  if _tmux_timeout 3 tmux has-session -t "$SESSION" 2>/dev/null; then
    log_info "session resume: $SESSION"
    echo -e "${GREEN}Resuming session: $SESSION${NC}"
  else
    log_info "session start: $SESSION layout=${LAYOUT:-$DEFAULT_LAYOUT}"
    echo -e "${BLUE}Starting new session: $SESSION${NC}"
    if [ -n "$LAYOUT" ]; then
      LAYOUT="$LAYOUT" bash "$SCRIPT" "$SESSION"
    else
      bash "$SCRIPT" "$SESSION"
    fi
  fi

  # iTerm2 -CC mode: opt-in via config, prompt on first encounter
  if [ "${TERM_PROGRAM:-}" = "iTerm.app" ] && [ -z "${BATIPANEL_ITERM_CC:-}" ]; then
    echo ""
    echo -e "${BLUE}iTerm2 detected!${NC}"
    echo "  iTerm2 supports native tmux integration (tmux -CC)."
    echo "  Panes become native iTerm2 splits instead of tmux UI."
    echo -e "  ${YELLOW}Note:${NC} tmux status bar and theme will not be visible in this mode."
    echo ""
    printf "Enable iTerm2 integration? [y/N] "
    local iterm_answer
    read -r iterm_answer
    if [[ "$iterm_answer" == [yY] ]]; then
      BATIPANEL_ITERM_CC="1"
    else
      BATIPANEL_ITERM_CC="0"
    fi
    # persist choice
    _save_config "BATIPANEL_ITERM_CC" "$BATIPANEL_ITERM_CC"
  fi

  echo -e "  ${YELLOW}Tip:${NC} Detach with Ctrl+b d  |  Stop with: b stop $SESSION"
  if [ "${BATIPANEL_ITERM_CC:-0}" = "1" ]; then
    exec tmux -CC attach -t "$SESSION"
  else
    exec tmux attach -t "$SESSION"
  fi
}

tmux_stop() {
  local SESSION="$1"
  local FORCE="${2:-}"
  validate_session_name "$SESSION" || return 1

  if _tmux_timeout 3 tmux has-session -t "$SESSION" 2>/dev/null; then
    if [[ "$FORCE" != "-f" && -t 0 ]]; then
      printf "Stop session '%s'? [y/N] " "$SESSION"
      local answer
      read -r answer
      if [[ "$answer" != [yY] ]]; then
        echo "Cancelled."
        return 0
      fi
    fi
    tmux kill-session -t "$SESSION" && { log_info "session stop: $SESSION"; echo -e "${RED}Stopped: $SESSION${NC}"; }
  else
    echo -e "${YELLOW}Session not found: $SESSION${NC}"
  fi
}

tmux_list() {
  echo -e "${BLUE}=== Active Sessions ===${NC}"
  # run tmux ls with 3s timeout to avoid hang on stale server
  local tmux_out
  if tmux_out=$(_tmux_timeout 3 tmux ls 2>/dev/null); then
    echo "$tmux_out"
  else
    echo "  (none)"
  fi
  echo ""
  echo -e "${BLUE}=== Registered Projects ===${NC}"
  list_projects
}

# list registered projects
list_projects() {
  local found=0
  for f in "$BATIPANEL_HOME"/projects/*.sh; do
    [ -f "$f" ] || continue
    local name
    name=$(basename "$f" .sh)
    echo "  - $name"
    found=1
  done
  if (( found == 0 )); then
    echo "  (none - run 'b new <name> <path>' to register a project)"
  fi
}
