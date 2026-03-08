#!/usr/bin/env bash
# batipanel layout - Classic balanced 6-panel grid
#
# ┌──────────────┬───────────────┬────────────────────┐
# │  remote-ctrl │  claude       │  btop              │
# ├──────────────┼───────────────┼────────────────────┤
# │  lazygit     │  terminal     │  file tree         │
# └──────────────┴───────────────┴────────────────────┘

SESSION="$1"
PROJECT="${2:-$(pwd)}"

init_layout "$SESSION" "$PROJECT"

P0=$(tmux list-panes -t "$SESSION" -F '#{pane_id}' | head -1)

# 3 columns: left(32%) | center(36%) | right(32%)
P1=$(tmux split-window -h -t "$P0" -c "$PROJECT" -p 68 -PF '#{pane_id}')
P2=$(tmux split-window -h -t "$P1" -c "$PROJECT" -p 53 -PF '#{pane_id}')

# Split each column top/bottom
P3=$(tmux split-window -v -t "$P0" -c "$PROJECT" -p 40 -PF '#{pane_id}')
P4=$(tmux split-window -v -t "$P1" -c "$PROJECT" -p 40 -PF '#{pane_id}')
P5=$(tmux split-window -v -t "$P2" -c "$PROJECT" -p 40 -PF '#{pane_id}')

wait_for_panes

# P0: remote-control, P1: claude, P2: btop
# P3: lazygit,        P4: terminal, P5: file tree
run_remote "$P0"
run_claude "$P1"
run_monitor "$P2"
run_lazygit "$P3"
tmux send-keys -t "$P4" "" ""
run_filetree "$P5"

tmux select-pane -t "$P1"
