#!/usr/bin/env bash
# batipanel 공통 함수

set -euo pipefail

BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"

# portable sed -i (macOS vs GNU)
_sed_i() {
  if [ "$(uname -s)" = "Darwin" ]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# 컬러 (터미널 지원 시에만)
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

# 설정 로드
TMUX_CONFIG="$BATIPANEL_HOME/config.sh"
DEFAULT_LAYOUT="7panel"
if [ -f "$TMUX_CONFIG" ]; then
  # shellcheck source=/dev/null
  source "$TMUX_CONFIG"
fi

# 세션명 유효성 검사
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

# 등록된 프로젝트 목록 출력
list_projects() {
  for f in "$BATIPANEL_HOME"/projects/*.sh; do
    [ -f "$f" ] || continue
    local name
    name=$(basename "$f" .sh)
    echo "  - $name"
  done
}

# 사용 가능한 레이아웃 목록
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
    echo "Project directory not found: $project"
    exit 1
  fi
  tmux kill-session -t "$session" 2>/dev/null || true
  tmux new-session -d -s "$session" -c "$project"
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
    tmux send-keys -t "$pane" "echo 'lazygit not installed - brew install lazygit'; git status" Enter
  fi
}

# Launch file tree: yazi → eza → tree → find
run_filetree() {
  local pane="$1"
  if has_cmd yazi; then
    tmux send-keys -t "$pane" "yazi" Enter
  elif has_cmd eza; then
    tmux send-keys -t "$pane" "while clear; do eza --tree --level=3 --git --icons; sleep 3; done" Enter
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
    tmux send-keys -t "$pane" "docker ps; echo ''; echo 'lazydocker not installed — brew install lazydocker'" Enter
  else
    tmux send-keys -t "$pane" "echo 'docker / lazydocker not installed'" Enter
  fi
}

# 레이아웃 로드
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

  # iTerm2면 -CC 모드, 아니면 일반 attach
  if [ "${TERM_PROGRAM:-}" = "iTerm.app" ]; then
    exec tmux -CC attach -t "$SESSION"
  else
    exec tmux attach -t "$SESSION"
  fi
}

tmux_stop() {
  local SESSION="$1"
  validate_session_name "$SESSION" || exit 1

  if tmux has-session -t "$SESSION" 2>/dev/null; then
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
      if [ ! -f "$BATIPANEL_HOME/layouts/${value}.sh" ]; then
        echo -e "${RED}Layout not found: $value${NC}"
        list_layouts
        return 1
      fi
      # config.sh 업데이트
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

  # 프로젝트 경로를 절대경로로 변환
  if [[ "$PROJECT_PATH" != /* ]]; then
    PROJECT_PATH="$(cd "$PROJECT_PATH" 2>/dev/null && pwd)" || {
      echo -e "${RED}Path not found: $2${NC}"
      exit 1
    }
  fi

  if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}Directory does not exist: $PROJECT_PATH${NC}"
    exit 1
  fi

  mkdir -p "$BATIPANEL_HOME/projects"

  # Generate project script (no sed — avoids special character issues)
  cat > "$BATIPANEL_HOME/projects/${SESSION}.sh" <<TMUXEOF
#!/usr/bin/env bash
SESSION="\${1:-${SESSION}}"
PROJECT='${PROJECT_PATH}'
BATIPANEL_HOME="\${BATIPANEL_HOME:-\$HOME/.batipanel}"
source "\$BATIPANEL_HOME/lib/common.sh"
load_layout "\$SESSION" "\$PROJECT" "\${LAYOUT:-}"
TMUXEOF
  chmod +x "$BATIPANEL_HOME/projects/${SESSION}.sh"

  echo -e "${GREEN}Project created: ${SESSION}${NC}"
  echo -e "${YELLOW}Start now: b ${SESSION}${NC}"
}
