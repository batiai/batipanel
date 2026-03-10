#!/usr/bin/env bash
# batipanel layout - Balanced 5-panel workspace
#
# ┌──────────────────────────────┬──────────────┐
# │                              │              │
# │  claude (main)               │  lazygit     │
# │  60% width, 65% height      │              │
# │                              │              │
# ├──────────────┬───────────────┼──────────────┤
# │ remote-ctrl  │  terminal     │  file tree   │
# └──────────────┴───────────────┴──────────────┘

SESSION="$1"
PROJECT="${2:-$(pwd)}"

init_layout "$SESSION" "$PROJECT"

CLAUDE=$(tmux list-panes -t "$SESSION" -F '#{pane_id}' | head -1)

# Top(65%) | Bottom(35%)
REMOTE=$(_split -v -t "$CLAUDE" -c "$PROJECT" -p 35 -PF '#{pane_id}')

# Top: left(60%) | right(40%)
LAZYGIT=$(_split -h -t "$CLAUDE" -c "$PROJECT" -p 40 -PF '#{pane_id}')

# Bottom: 3 columns
ZSH=$(_split -h -t "$REMOTE" -c "$PROJECT" -p 67 -PF '#{pane_id}')
EZA=$(_split -h -t "$ZSH" -c "$PROJECT" -p 50 -PF '#{pane_id}')

wait_for_panes

run_claude "$CLAUDE"
run_lazygit "$LAZYGIT"
run_remote "$REMOTE"
tmux send-keys -t "$ZSH" "" ""
run_filetree "$EZA"

tmux select-pane -t "$CLAUDE"
