#!/usr/bin/env bash
# batipanel common functions

set -euo pipefail

BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"
BATIPANEL_DEBUG="${BATIPANEL_DEBUG:-0}"

# portable sed -i (macOS vs GNU)
_sed_i() {
  if [ "$(uname -s)" = "Darwin" ]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# colors (only when terminal supports it)
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

debug_log() {
  [[ "$BATIPANEL_DEBUG" == "1" ]] && echo -e "${YELLOW}[debug]${NC} $*" >&2
  return 0
}

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

# terminal size check
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

# load config
TMUX_CONFIG="$BATIPANEL_HOME/config.sh"
DEFAULT_LAYOUT="7panel"
if [ -f "$TMUX_CONFIG" ]; then
  # shellcheck source=/dev/null
  source "$TMUX_CONFIG"
fi

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
    echo "  (none — run 'b new <name> <path>' to register a project)"
  fi
}

# list available layouts
list_layouts() {
  echo -e "${BLUE}=== Available Layouts ===${NC}"
  for f in "$BATIPANEL_HOME"/layouts/*.sh; do
    [ -f "$f" ] || continue
    local name
    name=$(basename "$f" .sh)
    local desc
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

# === Layout helper functions ===

has_cmd() { command -v "$1" &>/dev/null; }

# Initialize a layout session: validate dir, kill existing, create new
init_layout() {
  local session="$1"
  local project="${2:-$(pwd)}"
  if [ ! -d "$project" ]; then
    echo -e "${RED}Project directory not found: $project${NC}"
    exit 1
  fi

  check_tmux_version || exit 1

  debug_log "init_layout: session=$session project=$project"
  tmux kill-session -t "$session" 2>/dev/null || true
  if ! tmux new-session -d -s "$session" -c "$project"; then
    echo -e "${RED}Failed to create tmux session '$session'${NC}"
    echo "  Is another tmux server blocking? Try: tmux kill-server"
    exit 1
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
    tmux send-keys -t "$pane" "echo 'claude CLI not installed - npm i -g @anthropic-ai/claude-code'" Enter
  fi
}

# Launch claude remote-control in a pane
run_remote() {
  local pane="$1"
  if has_cmd claude; then
    tmux send-keys -t "$pane" "claude remote-control" Enter
  else
    tmux send-keys -t "$pane" "echo 'claude CLI not installed'" Enter
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
    tmux send-keys -t "$pane" "echo 'lazygit not installed — see https://github.com/jesseduffield/lazygit#installation'; git status" Enter
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
    tmux send-keys -t "$pane" "docker ps; echo ''; echo 'lazydocker not installed — see https://github.com/jesseduffield/lazydocker#installation'" Enter
  else
    tmux send-keys -t "$pane" "echo 'docker / lazydocker not installed'" Enter
  fi
}

# load layout
load_layout() {
  local session="$1"
  local project="$2"
  local layout="${3:-$DEFAULT_LAYOUT}"

  local layout_file="$BATIPANEL_HOME/layouts/${layout}.sh"
  if [ ! -f "$layout_file" ]; then
    echo -e "${RED}Layout not found: $layout${NC}"
    echo ""
    list_layouts
    exit 1
  fi

  check_terminal_size "$layout"
  debug_log "load_layout: $layout_file"

  # shellcheck source=/dev/null
  source "$layout_file" "$session" "$project"
}

tmux_start() {
  local SESSION="$1"
  local LAYOUT="${2:-}"
  local SCRIPT="$BATIPANEL_HOME/projects/${SESSION}.sh"

  validate_session_name "$SESSION" || exit 1

  if [ ! -f "$SCRIPT" ]; then
    echo -e "${RED}Project not found: ${SESSION}${NC}"
    echo -e "${YELLOW}Available projects:${NC}"
    list_projects
    exit 1
  fi

  if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo -e "${GREEN}Resuming session: $SESSION${NC}"
  else
    echo -e "${BLUE}Starting new session: $SESSION${NC}"
    if [ -n "$LAYOUT" ]; then
      LAYOUT="$LAYOUT" bash "$SCRIPT" "$SESSION"
    else
      bash "$SCRIPT" "$SESSION"
    fi
  fi

  # iTerm2: use -CC mode, otherwise normal attach
  if [ "${TERM_PROGRAM:-}" = "iTerm.app" ]; then
    exec tmux -CC attach -t "$SESSION"
  else
    exec tmux attach -t "$SESSION"
  fi
}

tmux_stop() {
  local SESSION="$1"
  local FORCE="${2:-}"
  validate_session_name "$SESSION" || exit 1

  if tmux has-session -t "$SESSION" 2>/dev/null; then
    if [[ "$FORCE" != "-f" && -t 0 ]]; then
      printf "Stop session '%s'? [y/N] " "$SESSION"
      local answer
      read -r answer
      if [[ "$answer" != [yY] ]]; then
        echo "Cancelled."
        return 0
      fi
    fi
    tmux kill-session -t "$SESSION" && echo -e "${RED}Stopped: $SESSION${NC}"
  else
    echo -e "${YELLOW}Session not found: $SESSION${NC}"
  fi
}

tmux_list() {
  echo -e "${BLUE}=== Active Sessions ===${NC}"
  tmux ls 2>/dev/null || echo "  (none)"
  echo ""
  echo -e "${BLUE}=== Registered Projects ===${NC}"
  list_projects
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
    "")
      echo "Usage: b config <key> [value]"
      echo ""
      echo "  b config layout          Show current default layout"
      echo "  b config layout 7panel   Change default layout"
      ;;
    *)
      echo -e "${RED}Unknown config key: $key${NC}"
      ;;
  esac
}

tmux_new() {
  local SESSION="$1"
  local PROJECT_PATH="${2:-$(pwd)}"

  if [ -z "$SESSION" ]; then
    echo "Usage: b new <name> [project-path]"
    exit 1
  fi

  validate_session_name "$SESSION" || exit 1

  # resolve to absolute path
  if [[ "$PROJECT_PATH" != /* ]]; then
    local original_path="$PROJECT_PATH"
    PROJECT_PATH="$(cd "$PROJECT_PATH" 2>/dev/null && pwd)" || {
      echo -e "${RED}Path not found: $original_path${NC}"
      exit 1
    }
  fi

  if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}Directory does not exist: $PROJECT_PATH${NC}"
    exit 1
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

# === Doctor: system health check ===

tmux_doctor() {
  local ok="${GREEN}OK${NC}"
  local warn="${YELLOW}WARN${NC}"
  local fail="${RED}FAIL${NC}"
  local issues=0

  echo ""
  echo -e "${BLUE}=== batipanel doctor ===${NC}"
  echo ""

  # 1. tmux
  if command -v tmux &>/dev/null; then
    local ver
    ver=$(tmux -V 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
    local major="${ver%%.*}" minor="${ver#*.}"
    if [[ -n "$ver" ]] && (( major >= 2 && (major > 2 || minor >= 6) )); then
      echo -e "  [$ok]  tmux $ver"
    else
      echo -e "  [$fail]  tmux ${ver:-unknown} (need 2.6+)"
      issues=$((issues + 1))
    fi
  else
    echo -e "  [$fail]  tmux not installed"
    issues=$((issues + 1))
  fi

  # 2. optional tools
  local tools=("claude:Claude Code" "lazygit:lazygit" "btop:btop" "yazi:yazi" "eza:eza")
  for entry in "${tools[@]}"; do
    local cmd="${entry%%:*}" name="${entry#*:}"
    if command -v "$cmd" &>/dev/null; then
      echo -e "  [$ok]  $name"
    else
      echo -e "  [$warn]  $name not installed (optional)"
    fi
  done

  # 3. fallback chain
  if ! command -v btop &>/dev/null; then
    if command -v htop &>/dev/null; then
      echo -e "  [${ok}]  monitor fallback: htop"
    elif command -v top &>/dev/null; then
      echo -e "  [${ok}]  monitor fallback: top"
    else
      echo -e "  [$warn]  no system monitor found"
    fi
  fi

  # 4. batipanel install
  echo ""
  if [ -f "$BATIPANEL_HOME/lib/common.sh" ]; then
    local installed_ver
    installed_ver=$(cat "$BATIPANEL_HOME/VERSION" 2>/dev/null || echo "unknown")
    echo -e "  [$ok]  batipanel v$installed_ver installed at $BATIPANEL_HOME"
  else
    echo -e "  [$fail]  batipanel not properly installed"
    issues=$((issues + 1))
  fi

  # 5. config
  if [ -f "$TMUX_CONFIG" ]; then
    echo -e "  [$ok]  config: $DEFAULT_LAYOUT layout"
  else
    echo -e "  [$warn]  no config.sh (run 'b' to set up)"
  fi

  # 6. projects
  local proj_count=0
  for f in "$BATIPANEL_HOME"/projects/*.sh; do
    [ -f "$f" ] && proj_count=$((proj_count + 1))
  done
  if (( proj_count > 0 )); then
    echo -e "  [$ok]  $proj_count project(s) registered"
  else
    echo -e "  [$warn]  no projects (run 'b new <name> <path>')"
  fi

  # 7. tmux.conf
  if [ -f "$HOME/.tmux.conf" ] && grep -q "batipanel" "$HOME/.tmux.conf" 2>/dev/null; then
    echo -e "  [$ok]  ~/.tmux.conf configured"
  else
    echo -e "  [$warn]  ~/.tmux.conf missing batipanel source line"
    echo "          Fix: echo 'source-file ~/.batipanel/config/tmux.conf' >> ~/.tmux.conf"
  fi

  # 8. shell alias
  local rc_found=0
  for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
    if [ -f "$rc" ] && grep -q "batipanel" "$rc" 2>/dev/null; then
      echo -e "  [$ok]  alias registered in $(basename "$rc")"
      rc_found=1
      break
    fi
  done
  if (( rc_found == 0 )); then
    echo -e "  [$warn]  no shell alias found"
    echo "          Fix: echo \"alias b='bash $BATIPANEL_HOME/bin/start.sh'\" >> ~/.zshrc"
  fi

  # 9. tab completion
  local comp_found=0
  for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
    if [ -f "$rc" ] && grep -q "completions/batipanel" "$rc" 2>/dev/null; then
      comp_found=1
      break
    fi
  done
  if (( comp_found == 1 )); then
    echo -e "  [$ok]  tab completion enabled"
  else
    echo -e "  [$warn]  tab completion not enabled"
    echo "          Fix: re-run install.sh or source ~/.batipanel/completions/batipanel.bash"
  fi

  # summary
  echo ""
  if (( issues == 0 )); then
    echo -e "  ${GREEN}All good!${NC}"
  else
    echo -e "  ${RED}$issues issue(s) found${NC}"
  fi
  echo ""
}

# === First-run wizard ===

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

  # Step 1: Screen size
  echo -e "${GREEN}Step 1/2: What is your screen size?${NC}"
  echo "  1) Small (laptop 13-14\")"
  echo "  2) Large (external monitor)  [default]"
  echo "  3) Ultrawide"
  echo ""
  printf "Choose [1-3]: "
  local screen_choice screen
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
  local workflow_choice workflow
  read -r workflow_choice
  workflow_choice="${workflow_choice:-1}"
  case "$workflow_choice" in
    2) workflow="general" ;;
    3) workflow="devops" ;;
    *) workflow="ai" ;;
  esac

  # Layout mapping
  local layout
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
  DEFAULT_LAYOUT="$layout"
  echo -e "${GREEN}Configuration saved.${NC}"
  echo ""

  # Offer to register current directory as project
  local cwd
  cwd=$(pwd)
  local proj_name
  proj_name=$(basename "$cwd" | tr -c 'a-zA-Z0-9_-' '-' | sed 's/-*$//')

  echo -e "Register ${BLUE}${cwd}${NC} as project '${GREEN}${proj_name}${NC}'?"
  printf "[Y/n] "
  local reg_answer
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
