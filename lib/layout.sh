#!/usr/bin/env bash
# batipanel layout - framework, tool launchers, layout listing

# Initialize a layout session: validate dir, kill existing, create new
init_layout() {
  local session="$1"
  local project="${2:-$(pwd)}"
  if [ ! -d "$project" ]; then
    echo -e "${RED}Project directory not found: $project${NC}"
    return 1
  fi

  check_tmux_version || return 1

  # Use large fixed size for detached session so all splits succeed.
  # tmux auto-resizes to actual terminal dimensions on attach.
  debug_log "init_layout: session=$session project=$project"
  tmux kill-session -t "$session" 2>/dev/null || true

  # try creating session; capture stderr for debug output
  local tmux_err
  tmux_err=$(tmux new-session -d -s "$session" -c "$project" -x 220 -y 60 2>&1) || {
    debug_log "init_layout: first attempt failed: $tmux_err"
    # retry with safe TERM
    debug_log "init_layout: retrying with TERM=xterm-256color"
    tmux_err=$(TERM=xterm-256color tmux new-session -d -s "$session" -c "$project" -x 220 -y 60 2>&1) || {
      debug_log "init_layout: second attempt failed: $tmux_err"
      # check if session was created by a concurrent invocation
      if tmux has-session -t "$session" 2>/dev/null; then
        debug_log "init_layout: session already exists (concurrent creation)"
        return 0
      fi
      echo -e "${RED}Failed to create tmux session '$session'${NC}"
      # provide specific guidance based on error
      if [[ "$tmux_err" == *"open terminal failed"* ]]; then
        echo "  Error: open terminal failed (terminfo issue)"
        echo "  Try: export TERM=xterm-256color && b $session"
      elif [[ "$tmux_err" == *"server"* ]] || [[ "$tmux_err" == *"socket"* ]]; then
        echo "  Stale tmux server? Try: tmux kill-server"
      elif [[ "$tmux_err" == *"library"* ]] || [[ "$tmux_err" == *"dylib"* ]]; then
        echo "  Library issue — try reinstalling tmux"
      else
        echo "  tmux error: $tmux_err"
      fi
      return 1
    }
  }
}

# Wait for shell init after pane splits
wait_for_panes() { sleep 0.5; }

# Compatible split-window: try with -p (percentage), fallback without it
# Usage: same as tmux split-window (drop-in replacement)
_split() {
  tmux split-window "$@" 2>/dev/null && return 0
  # strip -p <N> and retry (tmux versions where -p fails)
  local args=() skip=0
  for a in "$@"; do
    if (( skip )); then skip=0; continue; fi
    if [[ "$a" == "-p" ]]; then skip=1; continue; fi
    args+=("$a")
  done
  tmux split-window "${args[@]}"
}

# Set pane title (visible in border when pane-border-status is on)
label_pane() {
  local pane="$1" title="$2"
  tmux select-pane -t "$pane" -T "$title"
}

# Launch claude in a pane
run_claude() {
  local pane="$1"
  label_pane "$pane" "Claude"
  if has_cmd claude; then
    tmux send-keys -t "$pane" "claude" Enter
  else
    tmux send-keys -t "$pane" "echo 'claude CLI not installed - run: curl -fsSL https://claude.ai/install.sh | bash'" Enter
  fi
}

# Launch claude remote-control in a pane
run_remote() {
  local pane="$1"
  label_pane "$pane" "Remote"
  if has_cmd claude; then
    tmux send-keys -t "$pane" "claude remote-control" Enter
  else
    tmux send-keys -t "$pane" "echo 'claude CLI not installed - run: curl -fsSL https://claude.ai/install.sh | bash'" Enter
  fi
}

# Launch system monitor: btop → htop → top
# btop needs ~80x24 minimum; if pane is too small, let user choose
run_monitor() {
  local pane="$1"
  label_pane "$pane" "Monitor"
  if has_cmd btop; then
    local pw ph
    pw=$(tmux display-message -t "$pane" -p '#{pane_width}' 2>/dev/null || echo 0)
    ph=$(tmux display-message -t "$pane" -p '#{pane_height}' 2>/dev/null || echo 0)
    if (( pw >= 80 && ph >= 24 )); then
      tmux send-keys -t "$pane" "btop" Enter
    else
      # pane too small for btop — let user choose
      tmux send-keys -t "$pane" \
        "echo 'Pane is ${pw}x${ph} (btop needs 80x24)' && echo '' && echo '  1) btop  (force — or zoom with Alt+f first)' && echo '  2) htop' && echo '  3) top' && echo '' && printf 'Choose [1]: ' && read -r _c && case \${_c:-1} in 2) htop;; 3) top;; *) btop;; esac" Enter
    fi
  elif has_cmd htop; then
    tmux send-keys -t "$pane" "htop" Enter
  elif has_cmd top; then
    tmux send-keys -t "$pane" "top" Enter
  fi
}

# Launch lazygit or fallback
run_lazygit() {
  local pane="$1"
  label_pane "$pane" "Git"
  if has_cmd lazygit; then
    tmux send-keys -t "$pane" "lazygit" Enter
  else
    tmux send-keys -t "$pane" "echo 'lazygit not installed - see https://github.com/jesseduffield/lazygit#installation'; git status" Enter
  fi
}

# Launch file tree: yazi → eza → tree → find
run_filetree() {
  local pane="$1"
  label_pane "$pane" "Files"
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
  label_pane "$pane" "Docker"
  if has_cmd lazydocker; then
    tmux send-keys -t "$pane" "lazydocker" Enter
  elif has_cmd docker; then
    tmux send-keys -t "$pane" "docker ps; echo ''; echo 'lazydocker not installed - see https://github.com/jesseduffield/lazydocker#installation'" Enter
  else
    tmux send-keys -t "$pane" "echo 'docker / lazydocker not installed'" Enter
  fi
}

# Load and execute a layout
load_layout() {
  local session="$1"
  local project="$2"
  local layout="${3:-$DEFAULT_LAYOUT}"

  local layout_file="$BATIPANEL_HOME/layouts/${layout}.sh"
  if [ ! -f "$layout_file" ]; then
    echo -e "${RED}Layout not found: $layout${NC}"
    echo ""
    list_layouts
    return 1
  fi

  debug_log "load_layout: $layout_file"

  # temporarily disable errexit so partial split failures don't kill the session
  set +e
  # shellcheck source=/dev/null
  source "$layout_file" "$session" "$project"
  local rc=$?
  set -e

  if [ "$rc" -ne 0 ]; then
    debug_log "load_layout: layout exited with code $rc (partial setup possible)"
  fi
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
