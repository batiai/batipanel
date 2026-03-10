#!/usr/bin/env bash
# batipanel layout - framework, tool launchers, layout listing

has_cmd() { command -v "$1" &>/dev/null; }

# Initialize a layout session: validate dir, kill existing, create new
init_layout() {
  local session="$1"
  local project="${2:-$(pwd)}"
  if [ ! -d "$project" ]; then
    echo -e "${RED}Project directory not found: $project${NC}"
    return 1
  fi

  check_tmux_version || return 1

  # detect terminal size for detached session (default 80x24 is too small)
  local cols lines
  cols=$(tput cols 2>/dev/null || echo 200)
  lines=$(tput lines 2>/dev/null || echo 50)

  debug_log "init_layout: session=$session project=$project size=${cols}x${lines}"
  tmux kill-session -t "$session" 2>/dev/null || true
  if ! tmux new-session -d -s "$session" -c "$project" -x "$cols" -y "$lines"; then
    # check if session was created by a concurrent invocation
    if tmux has-session -t "$session" 2>/dev/null; then
      debug_log "init_layout: session already exists (concurrent creation)"
      return 0
    fi
    echo -e "${RED}Failed to create tmux session '$session'${NC}"
    echo "  Is another tmux server blocking? Try: tmux kill-server"
    return 1
  fi
}

# Wait for shell init after pane splits
wait_for_panes() { sleep 0.5; }

# Launch claude in a pane
run_claude() {
  local pane="$1"
  if has_cmd claude; then
    tmux send-keys -t "$pane" "claude" Enter
  else
    tmux send-keys -t "$pane" "echo 'claude CLI not installed - run: curl -fsSL https://claude.ai/install.sh | bash'" Enter
  fi
}

# Launch claude remote-control in a pane
run_remote() {
  local pane="$1"
  if has_cmd claude; then
    tmux send-keys -t "$pane" "claude remote-control" Enter
  else
    tmux send-keys -t "$pane" "echo 'claude CLI not installed - run: curl -fsSL https://claude.ai/install.sh | bash'" Enter
  fi
}

# Launch system monitor: btop → htop → top
run_monitor() {
  local pane="$1"
  if has_cmd btop; then
    tmux send-keys -t "$pane" "btop" Enter
  elif has_cmd htop; then
    tmux send-keys -t "$pane" "htop" Enter
  elif has_cmd top; then
    tmux send-keys -t "$pane" "top" Enter
  fi
}

# Launch lazygit or fallback
run_lazygit() {
  local pane="$1"
  if has_cmd lazygit; then
    tmux send-keys -t "$pane" "lazygit" Enter
  else
    tmux send-keys -t "$pane" "echo 'lazygit not installed - see https://github.com/jesseduffield/lazygit#installation'; git status" Enter
  fi
}

# Launch file tree: yazi → eza → tree → find
run_filetree() {
  local pane="$1"
  if has_cmd yazi; then
    tmux send-keys -t "$pane" "yazi" Enter
  elif has_cmd eza; then
    local eza_flags="--tree --level=3 --git"
    # --icons requires Nerd Font; enable only in known-capable terminals
    if [[ "${TERM_PROGRAM:-}" =~ ^(iTerm.app|WezTerm|kitty)$ ]] || [[ "${BATIPANEL_ICONS:-0}" == "1" ]]; then
      eza_flags+=" --icons"
    fi
    tmux send-keys -t "$pane" "while clear; do eza $eza_flags; sleep 3; done" Enter
  elif has_cmd tree; then
    tmux send-keys -t "$pane" "while clear; do tree -L 3; sleep 3; done" Enter
  else
    tmux send-keys -t "$pane" "while clear; do find . -maxdepth 3 -type d | head -50; sleep 5; done" Enter
  fi
}

# Launch lazydocker or fallback
run_lazydocker() {
  local pane="$1"
  if has_cmd lazydocker; then
    tmux send-keys -t "$pane" "lazydocker" Enter
  elif has_cmd docker; then
    tmux send-keys -t "$pane" "docker ps; echo ''; echo 'lazydocker not installed - see https://github.com/jesseduffield/lazydocker#installation'" Enter
  else
    tmux send-keys -t "$pane" "echo 'docker / lazydocker not installed'" Enter
  fi
}

# Auto-downgrade layout if terminal is too small
auto_fit_layout() {
  local layout="$1"
  local cols lines
  cols=$(tput cols 2>/dev/null || echo 0)
  lines=$(tput lines 2>/dev/null || echo 0)

  # can't detect size - keep as-is
  if (( cols == 0 || lines == 0 )); then
    echo "$layout"
    return
  fi

  # layout minimum requirements (cols x lines)
  local original="$layout"
  case "$layout" in
    dual-claude|8panel)
      if (( cols < 160 || lines < 40 )); then layout="6panel"; fi
      ;;
    7panel|7panel_log)
      if (( cols < 160 || lines < 40 )); then layout="5panel"; fi
      ;;
    6panel|devops)
      if (( cols < 140 || lines < 35 )); then layout="5panel"; fi
      ;;
  esac
  # second pass: downgraded layout may still be too large
  case "$layout" in
    5panel|6panel)
      if (( cols < 100 || lines < 24 )); then layout="4panel"; fi
      ;;
  esac

  if [ "$layout" != "$original" ]; then
    echo -e "${YELLOW}Terminal ${cols}x${lines} too small for '$original', using '$layout'${NC}" >&2
  fi
  echo "$layout"
}

# Load and execute a layout
load_layout() {
  local session="$1"
  local project="$2"
  local layout="${3:-$DEFAULT_LAYOUT}"

  # auto-downgrade if terminal too small
  layout=$(auto_fit_layout "$layout")

  local layout_file="$BATIPANEL_HOME/layouts/${layout}.sh"
  if [ ! -f "$layout_file" ]; then
    echo -e "${RED}Layout not found: $layout${NC}"
    echo ""
    list_layouts
    return 1
  fi

  check_terminal_size "$layout"
  debug_log "load_layout: $layout_file (${layout})"

  # shellcheck source=/dev/null
  source "$layout_file" "$session" "$project"
}

# List available layouts
list_layouts() {
  echo -e "${BLUE}=== Available Layouts ===${NC}"
  for f in "$BATIPANEL_HOME"/layouts/*.sh; do
    [ -f "$f" ] || continue
    local name desc
    name=$(basename "$f" .sh)
    desc=$(grep -m1 '^# batipanel layout' "$f" | sed 's/.*- //' || echo "")
    if [ "$name" = "$DEFAULT_LAYOUT" ]; then
      echo -e "  ${GREEN}* $name${NC} (default) $desc"
    else
      echo -e "  - $name  $desc"
    fi
  done
  echo ""
  echo -e "${YELLOW}Change default: b config layout <name>${NC}"
  echo -e "${YELLOW}One-time use:   b <project> --layout <name>${NC}"
}
