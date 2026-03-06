#!/usr/bin/env bash
# ~/tmux/layout_6panel.sh - 6분할 공통 레이아웃
#
# 레이아웃:
# ┌──────────────┬───────────────┬────────────────────┐
# │  0: remote   │  1: claude    │  2: btop           │
# │   control    │   (일반)      │   (리소스)         │
# ├──────────────┼───────────────┼────────────────────┤
# │  3: lazygit  │  4: zsh       │  5: eza tree       │
# │              │   (명령어)    │   (파일트리)       │
# └──────────────┴───────────────┴────────────────────┘

SESSION="$1"
PROJECT="${2:-$(pwd)}"

# 프로젝트 디렉토리 확인
if [ ! -d "$PROJECT" ]; then
  echo "프로젝트 디렉토리가 존재하지 않습니다: $PROJECT"
  exit 1
fi

# 의존성 체크 헬퍼
has_cmd() { command -v "$1" &>/dev/null; }

# 기존 세션 정리 후 생성
tmux kill-session -t "$SESSION" 2>/dev/null || true
tmux new-session -d -s "$SESSION" -c "$PROJECT"

# === 3컬럼 분할 ===
# 전체를 좌(32%) | 중(36%) | 우(32%) 로 분할
tmux split-window -h -t "$SESSION" -c "$PROJECT" -p 68
tmux split-window -h -t "${SESSION}:0.1" -c "$PROJECT" -p 53

# === 상하 분할 ===
tmux split-window -v -t "${SESSION}:0.0" -c "$PROJECT" -p 40
tmux split-window -v -t "${SESSION}:0.1" -c "$PROJECT" -p 40
tmux split-window -v -t "${SESSION}:0.2" -c "$PROJECT" -p 40

# === 각 패널 명령 실행 ===

# pane 0: claude remote-control
if has_cmd claude; then
  tmux send-keys -t "${SESSION}:0.0" "claude remote-control" Enter
else
  tmux send-keys -t "${SESSION}:0.0" "echo 'claude CLI 미설치 - npm i -g @anthropic-ai/claude-code'" Enter
fi

# pane 1: claude 일반
if has_cmd claude; then
  tmux send-keys -t "${SESSION}:0.1" "claude" Enter
else
  tmux send-keys -t "${SESSION}:0.1" "echo 'claude CLI 미설치'" Enter
fi

# pane 2: btop (리소스 모니터)
if has_cmd btop; then
  tmux send-keys -t "${SESSION}:0.2" "btop" Enter
elif has_cmd htop; then
  tmux send-keys -t "${SESSION}:0.2" "htop" Enter
elif has_cmd top; then
  tmux send-keys -t "${SESSION}:0.2" "top" Enter
fi

# pane 3: lazygit
if has_cmd lazygit; then
  tmux send-keys -t "${SESSION}:0.3" "lazygit" Enter
else
  tmux send-keys -t "${SESSION}:0.3" "echo 'lazygit 미설치 - brew install lazygit'; git status" Enter
fi

# pane 4: zsh (빈 터미널)
tmux send-keys -t "${SESSION}:0.4" "echo '프로젝트: $PROJECT'" Enter

# pane 5: eza 파일트리 (watch로 실시간 갱신)
if has_cmd eza; then
  tmux send-keys -t "${SESSION}:0.5" "watch -n3 'eza --tree --level=3 --git --icons'" Enter
elif has_cmd tree; then
  tmux send-keys -t "${SESSION}:0.5" "watch -n3 'tree -L 3'" Enter
else
  tmux send-keys -t "${SESSION}:0.5" "watch -n5 'find . -maxdepth 3 -type d | head -50'" Enter
fi

# 포커스를 claude 일반(pane 1)으로
tmux select-pane -t "${SESSION}:0.1"
