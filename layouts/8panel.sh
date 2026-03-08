#!/usr/bin/env bash
# batipanel layout - 8-panel dual Claude workspace
#
# ┌──────────────┬──────────────┬──────────────┐
# │              │              │              │
# │  claude #1   │  claude #2   │  btop        │
# │  (main)      │  (secondary) │              │
# │              │              ├──────────────┤
# │              │              │  logs        │
# ├──────────────┴──────────────┼──────────────┤
# │  lazygit                    │  file mgr    │
# └─────────────────────────────┴──────────────┘

SESSION="$1"
PROJECT="${2:-$(pwd)}"

init_layout "$SESSION" "$PROJECT"

CLAUDE1=$(tmux list-panes -t "$SESSION" -F '#{pane_id}' | head -1)

# Top(65%) | Bottom(35%)
LAZYGIT=$(tmux split-window -v -t "$CLAUDE1" -c "$PROJECT" -p 35 -PF '#{pane_id}')

# Top: 3 columns — left(37%) | center(37%) | right(26%)
CLAUDE2=$(tmux split-window -h -t "$CLAUDE1" -c "$PROJECT" -p 63 -PF '#{pane_id}')
BTOP=$(tmux split-window -h -t "$CLAUDE2" -c "$PROJECT" -p 42 -PF '#{pane_id}')

# Right column: btop(50%) | logs(50%)
LOGS=$(tmux split-window -v -t "$BTOP" -c "$PROJECT" -p 50 -PF '#{pane_id}')

# Bottom: left(65%) | right(35%)
FILEMGR=$(tmux split-window -h -t "$LAZYGIT" -c "$PROJECT" -p 35 -PF '#{pane_id}')

wait_for_panes

run_claude "$CLAUDE1"
run_claude "$CLAUDE2"
run_monitor "$BTOP"
tmux send-keys -t "$LOGS" "echo 'Logs — tail -f, npm run dev, docker logs, etc.'" Enter
run_lazygit "$LAZYGIT"
run_filetree "$FILEMGR"

tmux select-pane -t "$CLAUDE1"
