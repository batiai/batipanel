#!/usr/bin/env bash
# ~/tmux/layout_7panel_log.sh - 하단 전폭 로그 7분할 레이아웃
#
# ┌───────────────────────┬───────────┬───────────┐
# │  0: claude (메인)     │ 1: lazygit│ 2: btop   │
# │  넓게 (45%)           │           │           │
# ├───────────┬───────────┼───────────┼───────────┤
# │ 3: remote │ 4: zsh    │ 5: eza    │           │
# │  control  │ (명령어)  │  tree     │           │
# ├───────────┴───────────┴───────────┴───────────┤
# │  6: 로그 전체폭 (tail -f / npm run dev)       │
# └───────────────────────────────────────────────┘

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
# Step 1: 하단 로그 25% 분리
tmux split-window -v -t "$SESSION" -c "$PROJECT" -p 25

# Step 2: 상단을 3컬럼 (claude 45% | lazygit 28% | btop 27%)
tmux split-window -h -t "${SESSION}:0.0" -c "$PROJECT" -p 55
tmux split-window -h -t "${SESSION}:0.1" -c "$PROJECT" -p 50

# Step 3: 좌측(claude) 하단 분리 → remote + zsh
tmux split-window -v -t "${SESSION}:0.0" -c "$PROJECT" -p 40
# 하단을 좌우로 분할
tmux split-window -h -t "${SESSION}:0.4" -c "$PROJECT" -p 50

# Step 4: 중앙(lazygit) 하단에 eza 분리
tmux split-window -v -t "${SESSION}:0.1" -c "$PROJECT" -p 40

# === 각 패널 명령 실행 ===

# pane 0: claude (메인)
if has_cmd claude; then
  tmux send-keys -t "${SESSION}:0.0" "claude" Enter
else
  tmux send-keys -t "${SESSION}:0.0" "echo 'claude CLI 미설치 - npm i -g @anthropic-ai/claude-code'" Enter
fi

# pane 1: lazygit
if has_cmd lazygit; then
  tmux send-keys -t "${SESSION}:0.1" "lazygit" Enter
else
  tmux send-keys -t "${SESSION}:0.1" "echo 'lazygit 미설치'; git status" Enter
fi

# pane 2: btop
if has_cmd btop; then
  tmux send-keys -t "${SESSION}:0.2" "btop" Enter
elif has_cmd htop; then
  tmux send-keys -t "${SESSION}:0.2" "htop" Enter
elif has_cmd top; then
  tmux send-keys -t "${SESSION}:0.2" "top" Enter
fi

# pane 3: 로그 (하단 전폭)
tmux send-keys -t "${SESSION}:0.3" "echo '로그 패널 - tail -f, docker logs, npm run dev 등 사용'" Enter

# pane 4: remote-control
if has_cmd claude; then
  tmux send-keys -t "${SESSION}:0.4" "claude remote-control" Enter
else
  tmux send-keys -t "${SESSION}:0.4" "echo 'claude CLI 미설치'" Enter
fi

# pane 5: zsh
tmux send-keys -t "${SESSION}:0.5" "echo '프로젝트: $PROJECT'" Enter

# pane 6: eza tree
if has_cmd eza; then
  tmux send-keys -t "${SESSION}:0.6" "watch -n3 'eza --tree --level=3 --git --icons'" Enter
elif has_cmd tree; then
  tmux send-keys -t "${SESSION}:0.6" "watch -n3 'tree -L 3'" Enter
else
  tmux send-keys -t "${SESSION}:0.6" "watch -n5 'find . -maxdepth 3 -type d | head -50'" Enter
fi

# 포커스를 claude(pane 0)으로
tmux select-pane -t "${SESSION}:0.0"
