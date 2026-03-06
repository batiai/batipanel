#!/usr/bin/env bash
# ~/tmux/start.sh - batipanel 메인 진입점
# alias b='bash ~/tmux/start.sh' 로 등록해서 사용

source ~/tmux/common.sh

show_help() {
  echo ""
  echo "  batipanel - AI workspace manager"
  echo ""
  echo "  b <프로젝트>                  시작 or 복귀"
  echo "  b <프로젝트> --layout <이름>  레이아웃 지정해서 시작"
  echo "  b new <이름> [경로]           새 프로젝트 등록"
  echo "  b stop <프로젝트>             세션 종료"
  echo "  b ls                          세션/프로젝트 목록"
  echo "  b layouts                     사용 가능한 레이아웃"
  echo "  b config layout [이름]        기본 레이아웃 설정"
  echo ""
  echo "예시:"
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
      shift 2 || { echo -e "${RED}--layout 뒤에 레이아웃 이름을 입력하세요${NC}"; exit 1; }
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
    if [ -f ~/tmux/"${ARGS[0]}.sh" ]; then
      tmux_start "${ARGS[0]}" "$LAYOUT_ARG"
    else
      echo -e "${RED}알 수 없는 명령: ${ARGS[0]}${NC}"
      echo "  b help 으로 사용법 확인"
      exit 1
    fi
    ;;
esac
