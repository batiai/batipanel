#!/usr/bin/env bash
# batipanel layout - Dual Claude multi-agent workspace
#
# Two Claude instances side by side for parallel tasks.
# e.g., left for feature implementation, right for tests
#
# ┌──────────────────┬──────────────────┐
# │                  │                  │
# │  claude #1       │  claude #2       │
# │  (main)          │  (secondary)     │
# │                  │                  │
# ├──────────┬───────┴──────┬───────────┤
# │ lazygit  │  terminal    │ file mgr  │
# └──────────┴──────────────┴───────────┘

SESSION="$1"
PROJECT="${2:-$(pwd)}"

init_layout "$SESSION" "$PROJECT"

CLAUDE1=$(tmux list-panes -t "$SESSION" -F '#{pane_id}' | head -1)

# Top(65%) | Bottom(35%)
LAZYGIT=$(tmux split-window -v -t "$CLAUDE1" -c "$PROJECT" -p 35 -PF '#{pane_id}')

# Top: left(50%) | right(50%)
CLAUDE2=$(tmux split-window -h -t "$CLAUDE1" -c "$PROJECT" -p 50 -PF '#{pane_id}')

# Bottom: 3 columns
ZSH=$(tmux split-window -h -t "$LAZYGIT" -c "$PROJECT" -p 67 -PF '#{pane_id}')
FILEMGR=$(tmux split-window -h -t "$ZSH" -c "$PROJECT" -p 50 -PF '#{pane_id}')

wait_for_panes

run_claude "$CLAUDE1"
run_claude "$CLAUDE2"
run_lazygit "$LAZYGIT"
tmux send-keys -t "$ZSH" "" ""
run_filetree "$FILEMGR"

tmux select-pane -t "$CLAUDE1"
