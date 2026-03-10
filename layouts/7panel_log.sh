#!/usr/bin/env bash
# batipanel layout - 7-panel with full-width log bar
#
# ┌───────────────────────┬───────────┬───────────┐
# │  claude (main)        │ lazygit   │ btop      │
# ├──────────┬────────────┤           │           │
# │ remote   │ terminal   ├───────────┤           │
# │          │            │ file tree │           │
# ├──────────┴────────────┴───────────┴───────────┤
# │  logs — full width (tail -f / npm run dev)    │
# └───────────────────────────────────────────────┘

SESSION="$1"
PROJECT="${2:-$(pwd)}"

init_layout "$SESSION" "$PROJECT"

CLAUDE=$(tmux list-panes -t "$SESSION" -F '#{pane_id}' | head -1)

# Bottom log bar (25%)
LOGS=$(_split -v -t "$CLAUDE" -c "$PROJECT" -p 25 -PF '#{pane_id}')

# Top: 3 columns (claude 45% | lazygit 28% | btop 27%)
LAZYGIT=$(_split -h -t "$CLAUDE" -c "$PROJECT" -p 55 -PF '#{pane_id}')
BTOP=$(_split -h -t "$LAZYGIT" -c "$PROJECT" -p 50 -PF '#{pane_id}')

# Left column: split bottom → remote + terminal
REMOTE=$(_split -v -t "$CLAUDE" -c "$PROJECT" -p 40 -PF '#{pane_id}')
ZSH=$(_split -h -t "$REMOTE" -c "$PROJECT" -p 50 -PF '#{pane_id}')

# Center column: split bottom → file tree
EZA=$(_split -v -t "$LAZYGIT" -c "$PROJECT" -p 40 -PF '#{pane_id}')

wait_for_panes

run_claude "$CLAUDE"
run_lazygit "$LAZYGIT"
run_monitor "$BTOP"
tmux send-keys -t "$LOGS" "echo 'Logs — tail -f, docker logs, npm run dev, etc.'" Enter
run_remote "$REMOTE"
tmux send-keys -t "$ZSH" "" ""
run_filetree "$EZA"

tmux select-pane -t "$CLAUDE"
