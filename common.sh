#!/usr/bin/env bash
# ~/tmux/common.sh - 공통 함수

set -euo pipefail

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
TMUX_CONFIG=~/tmux/config.sh
DEFAULT_LAYOUT="7panel"
if [ -f "$TMUX_CONFIG" ]; then
  # shellcheck source=/dev/null
  source "$TMUX_CONFIG"
fi

# 세션명 유효성 검사
validate_session_name() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo -e "${RED}세션명을 입력하세요${NC}"
    return 1
  fi
  if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo -e "${RED}세션명에는 영문, 숫자, _, - 만 사용 가능합니다: $name${NC}"
    return 1
  fi
}

# 등록된 프로젝트 목록 출력
list_projects() {
  for f in ~/tmux/*.sh; do
    [ -f "$f" ] || continue
    local name
    name=$(basename "$f" .sh)
    case "$name" in
      common|start|layout_*) continue ;;
    esac
    echo "  - $name"
  done
}

# 사용 가능한 레이아웃 목록
list_layouts() {
  echo -e "${BLUE}=== 사용 가능한 레이아웃 ===${NC}"
  for f in ~/tmux/layout_*.sh; do
    [ -f "$f" ] || continue
    local name
    name=$(basename "$f" .sh)
    name="${name#layout_}"
    local desc
    desc=$(grep -m1 '^# ~/tmux/layout_' "$f" | sed 's/.*- //' || echo "")
    if [ "$name" = "$DEFAULT_LAYOUT" ]; then
      echo -e "  ${GREEN}* $name${NC} (기본값) $desc"
    else
      echo -e "  - $name  $desc"
    fi
  done
  echo ""
  echo -e "${YELLOW}기본값 변경: t config layout <이름>${NC}"
  echo -e "${YELLOW}임시 변경:   t <프로젝트> --layout <이름>${NC}"
}

# 레이아웃 로드
load_layout() {
  local session="$1"
  local project="$2"
  local layout="${3:-$DEFAULT_LAYOUT}"

  local layout_file=~/tmux/layout_${layout}.sh
  if [ ! -f "$layout_file" ]; then
    echo -e "${RED}레이아웃을 찾을 수 없습니다: $layout${NC}"
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
  local SCRIPT=~/tmux/${SESSION}.sh

  validate_session_name "$SESSION" || exit 1

  if [ ! -f "$SCRIPT" ]; then
    echo -e "${RED}~/tmux/${SESSION}.sh 없음${NC}"
    echo -e "${YELLOW}사용 가능한 프로젝트:${NC}"
    list_projects
    exit 1
  fi

  if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo -e "${GREEN}기존 세션 복귀: $SESSION${NC}"
  else
    echo -e "${BLUE}새 세션 시작: $SESSION${NC}"
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
    tmux kill-session -t "$SESSION" && echo -e "${RED}종료: $SESSION${NC}"
  else
    echo -e "${YELLOW}없는 세션: $SESSION${NC}"
  fi
}

tmux_list() {
  echo -e "${BLUE}=== 활성 세션 ===${NC}"
  tmux ls 2>/dev/null || echo "  없음"
  echo ""
  echo -e "${BLUE}=== 등록된 프로젝트 ===${NC}"
  list_projects
}

tmux_config() {
  local key="${1:-}"
  local value="${2:-}"

  case "$key" in
    layout)
      if [ -z "$value" ]; then
        echo -e "현재 기본 레이아웃: ${GREEN}$DEFAULT_LAYOUT${NC}"
        echo ""
        list_layouts
        return
      fi
      if [ ! -f ~/tmux/layout_"${value}".sh ]; then
        echo -e "${RED}레이아웃을 찾을 수 없습니다: $value${NC}"
        list_layouts
        return 1
      fi
      # config.sh 업데이트
      if [ -f "$TMUX_CONFIG" ]; then
        if grep -q "DEFAULT_LAYOUT=" "$TMUX_CONFIG"; then
          sed -i '' "s|DEFAULT_LAYOUT=.*|DEFAULT_LAYOUT=\"$value\"|" "$TMUX_CONFIG"
        else
          echo "DEFAULT_LAYOUT=\"$value\"" >> "$TMUX_CONFIG"
        fi
      else
        echo "DEFAULT_LAYOUT=\"$value\"" > "$TMUX_CONFIG"
      fi
      echo -e "${GREEN}기본 레이아웃 변경: $value${NC}"
      ;;
    "")
      echo "사용법: t config <key> [value]"
      echo ""
      echo "  t config layout          현재 기본 레이아웃 확인"
      echo "  t config layout 7panel   기본 레이아웃 변경"
      ;;
    *)
      echo -e "${RED}알 수 없는 설정: $key${NC}"
      ;;
  esac
}

tmux_new() {
  local SESSION="$1"
  local PROJECT_PATH="${2:-$(pwd)}"

  if [ -z "$SESSION" ]; then
    echo "사용법: t new <세션명> [프로젝트경로]"
    exit 1
  fi

  validate_session_name "$SESSION" || exit 1

  # 프로젝트 경로를 절대경로로 변환
  if [[ "$PROJECT_PATH" != /* ]]; then
    PROJECT_PATH="$(cd "$PROJECT_PATH" 2>/dev/null && pwd)" || {
      echo -e "${RED}경로를 찾을 수 없습니다: $2${NC}"
      exit 1
    }
  fi

  if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}디렉토리가 존재하지 않습니다: $PROJECT_PATH${NC}"
    exit 1
  fi

  # 안전한 스크립트 생성 (변수 주입 방지)
  cat > ~/tmux/"${SESSION}.sh" << 'TMUXEOF'
#!/usr/bin/env bash
SESSION="${1:-__SESSION__}"
PROJECT="__PROJECT__"
source ~/tmux/common.sh
load_layout "$SESSION" "$PROJECT" "${LAYOUT:-}"
TMUXEOF

  sed -i '' "s|__SESSION__|${SESSION}|g" ~/tmux/"${SESSION}.sh"
  sed -i '' "s|__PROJECT__|${PROJECT_PATH}|g" ~/tmux/"${SESSION}.sh"
  chmod +x ~/tmux/"${SESSION}.sh"

  echo -e "${GREEN}~/tmux/${SESSION}.sh 생성됨${NC}"
  echo -e "${YELLOW}바로 시작: t ${SESSION}${NC}"
}
