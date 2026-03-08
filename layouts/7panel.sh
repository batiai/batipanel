#!/usr/bin/env bash
# batipanel layout - Claude-focused 7-panel workspace (default)
#
# ┌──────────────────────────────┬──────────────┐
# │                              │ btop         │
# │  claude (main workspace)    ├──────────────┤
# │  55% width, 70% height      │ file tree    │
# │                              ├──────────────┤
# │                              │ remote-ctrl  │
# ├───────────┬──────────┬───────┴──────────────┤
# │ lazygit   │ terminal │ logs/server           │
# └───────────┴──────────┴──────────────────────┘

SESSION="$1"
PROJECT="${2:-$(pwd)}"

init_layout "$SESSION" "$PROJECT"

CLAUDE=$(tmux list-panes -t "$SESSION" -F '#{pane_id}' | head -1)

# Top(70%) | Bottom(30%)
LAZYGIT=$(tmux split-window -v -t "$CLAUDE" -c "$PROJECT" -p 30 -PF '#{pane_id}')

# Top: left(55%) | right(45%)
BTOP=$(tmux split-window -h -t "$CLAUDE" -c "$PROJECT" -p 45 -PF '#{pane_id}')

# Right column: 3 rows
EZA=$(tmux split-window -v -t "$BTOP" -c "$PROJECT" -p 67 -PF '#{pane_id}')
REMOTE=$(tmux split-window -v -t "$EZA" -c "$PROJECT" -p 50 -PF '#{pane_id}')

# Bottom: 3 columns
ZSH=$(tmux split-window -h -t "$LAZYGIT" -c "$PROJECT" -p 67 -PF '#{pane_id}')
LOGS=$(tmux split-window -h -t "$ZSH" -c "$PROJECT" -p 50 -PF '#{pane_id}')

wait_for_panes

run_claude "$CLAUDE"
run_monitor "$BTOP"
run_filetree "$EZA"
run_remote "$REMOTE"
run_lazygit "$LAZYGIT"
tmux send-keys -t "$ZSH" "" ""
tmux send-keys -t "$LOGS" "echo 'Logs — tail -f, npm run dev, etc.'" Enter

tmux select-pane -t "$CLAUDE"
