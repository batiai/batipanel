#!/usr/bin/env bash
# batipanel setup - first-run detection and interactive wizard

is_first_run() {
  # First run if no config.sh AND no registered projects
  [[ ! -f "$TMUX_CONFIG" ]] || return 1
  local found=0
  for f in "$BATIPANEL_HOME"/projects/*.sh; do
    [ -f "$f" ] && found=1 && break
  done
  (( found == 0 ))
}

run_wizard() {
  echo ""
  echo -e "${BLUE}=== Welcome to batipanel! ===${NC}"
  echo ""
  echo "Let's set up your workspace in 2 quick steps."
  echo ""

  local screen_choice screen workflow_choice workflow layout

  # Step 1: Screen size
  echo -e "${GREEN}Step 1/2: What is your screen size?${NC}"
  echo "  1) Small (laptop 13-14\")"
  echo "  2) Large (external monitor)  [default]"
  echo "  3) Ultrawide"
  echo ""
  printf "Choose [1-3]: "
  read -r screen_choice
  screen_choice="${screen_choice:-2}"
  case "$screen_choice" in
    1) screen="small" ;;
    3) screen="ultrawide" ;;
    *) screen="large" ;;
  esac
  echo ""

  # Step 2: Workflow
  echo -e "${GREEN}Step 2/2: What is your primary workflow?${NC}"
  echo "  1) AI coding (Claude Code)  [default]"
  echo "  2) General development"
  echo "  3) DevOps / infrastructure"
  echo ""
  printf "Choose [1-3]: "
  read -r workflow_choice
  workflow_choice="${workflow_choice:-1}"
  case "$workflow_choice" in
    2) workflow="general" ;;
    3) workflow="devops" ;;
    *) workflow="ai" ;;
  esac

  # Layout mapping
  case "${screen}:${workflow}" in
    small:ai)       layout="4panel" ;;
    small:general)  layout="4panel" ;;
    small:devops)   layout="devops" ;;
    large:ai)       layout="7panel" ;;
    large:general)  layout="6panel" ;;
    large:devops)   layout="devops" ;;
    ultrawide:ai)   layout="dual-claude" ;;
    ultrawide:general) layout="7panel_log" ;;
    ultrawide:devops)  layout="devops" ;;
    *)              layout="7panel" ;;
  esac

  echo ""
  echo -e "Selected layout: ${GREEN}${layout}${NC}"
  echo ""

  # Save config
  mkdir -p "$BATIPANEL_HOME"
  echo "DEFAULT_LAYOUT=\"$layout\"" > "$TMUX_CONFIG"
  # shellcheck disable=SC2034
  DEFAULT_LAYOUT="$layout"
  echo -e "${GREEN}Configuration saved.${NC}"
  echo ""

  # Offer to register current directory as project
  local cwd proj_name reg_answer
  cwd=$(pwd)
  proj_name=$(basename "$cwd" | tr -c 'a-zA-Z0-9_-' '-' | sed 's/-*$//')

  echo -e "Register ${BLUE}${cwd}${NC} as project '${GREEN}${proj_name}${NC}'?"
  printf "[Y/n] "
  read -r reg_answer
  if [[ "$reg_answer" != [nN] ]]; then
    tmux_new "$proj_name" "$cwd"
    echo ""
    echo -e "${GREEN}Starting ${proj_name}...${NC}"
    tmux_start "$proj_name" ""
  else
    echo ""
    echo "No problem! Here's how to get started:"
    echo "  b new <name> <path>   Register a project"
    echo "  b <project>           Start a session"
    echo "  b help                Show full help"
  fi
}
