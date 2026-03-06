#!/usr/bin/env bash
# ~/tmux/layout_7panel.sh - claude 중심 7분할 레이아웃 (기본값)
#
# ┌──────────────────────────────┬──────────────┐
# │                              │ 1: btop      │
# │  0: claude (메인 작업)       ├──────────────┤
# │  화면의 55%, 높이 70%        │ 2: eza tree  │
# │                              ├──────────────┤
# │                              │ 3: remote    │
# ├───────────┬──────────────────┴──────────────┤
# │ 4: lazygit│ 5: zsh (명령어) │ 6: 로그/서버  │
# └───────────┴─────────────────┴───────────────┘

SESSION="$1"
PROJECT="${2:-$(pwd)}"

if [ ! -d "$PROJECT" ]; then
  echo "프로젝트 디렉토리가 존재하지 않습니다: $PROJECT"
  exit 1
fi

has_cmd() { command -v "$1" &>/dev/null; }

# 기존 세션 정리 후 생성
tmux kill-session -t "$SESSION" 2>/dev/null || true
tmux new-session -d -s "$SESSION" -c "$PROJECT"

# === 분할 ===
# Step 1: 좌(55%) | 우(45%)
tmux split-window -h -t "$SESSION" -c "$PROJECT" -p 45

# Step 2: 우측을 3등분 (btop | eza | remote)
tmux split-window -v -t "${SESSION}:0.1" -c "$PROJECT" -p 67
tmux split-window -v -t "${SESSION}:0.2" -c "$PROJECT" -p 50

# Step 3: 좌측 하단 30% 분리 (claude 70% | 하단 30%)
tmux split-window -v -t "${SESSION}:0.0" -c "$PROJECT" -p 30

# Step 4: 하단을 3등분 (lazygit | zsh | log)
tmux split-window -h -t "${SESSION}:0.4" -c "$PROJECT" -p 67
tmux split-window -h -t "${SESSION}:0.5" -c "$PROJECT" -p 50

# === 각 패널 명령 실행 ===

# pane 0: claude (메인 작업)
if has_cmd claude; then
  tmux send-keys -t "${SESSION}:0.0" "claude" Enter
else
  tmux send-keys -t "${SESSION}:0.0" "echo 'claude CLI 미설치 - npm i -g @anthropic-ai/claude-code'" Enter
fi

# pane 1: btop (리소스 모니터)
if has_cmd btop; then
  tmux send-keys -t "${SESSION}:0.1" "btop" Enter
elif has_cmd htop; then
  tmux send-keys -t "${SESSION}:0.1" "htop" Enter
elif has_cmd top; then
  tmux send-keys -t "${SESSION}:0.1" "top" Enter
fi

# pane 2: eza 파일트리
if has_cmd eza; then
  tmux send-keys -t "${SESSION}:0.2" "watch -n3 'eza --tree --level=3 --git --icons'" Enter
elif has_cmd tree; then
  tmux send-keys -t "${SESSION}:0.2" "watch -n3 'tree -L 3'" Enter
else
  tmux send-keys -t "${SESSION}:0.2" "watch -n5 'find . -maxdepth 3 -type d | head -50'" Enter
fi

# pane 3: remote-control
if has_cmd claude; then
  tmux send-keys -t "${SESSION}:0.3" "claude remote-control" Enter
else
  tmux send-keys -t "${SESSION}:0.3" "echo 'claude CLI 미설치'" Enter
fi

# pane 4: lazygit
if has_cmd lazygit; then
  tmux send-keys -t "${SESSION}:0.4" "lazygit" Enter
else
  tmux send-keys -t "${SESSION}:0.4" "echo 'lazygit 미설치 - brew install lazygit'; git status" Enter
fi

# pane 5: zsh (빈 터미널)
tmux send-keys -t "${SESSION}:0.5" "echo '프로젝트: $PROJECT'" Enter

# pane 6: 로그/서버 출력용
tmux send-keys -t "${SESSION}:0.6" "echo '로그 패널 - tail -f, npm run dev 등 사용'" Enter

# 포커스를 claude(pane 0)으로
tmux select-pane -t "${SESSION}:0.0"
