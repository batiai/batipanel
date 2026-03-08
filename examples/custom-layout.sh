#!/usr/bin/env bash
# Example: Custom 3-panel layout
#
# Create your own layout by copying this file:
#   cp examples/custom-layout.sh ~/.batipanel/layouts/custom.sh
#   b myproject --layout custom
#
# ┌──────────────────────────┬──────────────────┐
# │                          │                  │
# │  claude (main)           │  terminal        │
# │  65% width               │                  │
# │                          │                  │
# ├──────────────────────────┴──────────────────┤
# │  lazygit (full width, 30% height)           │
# └─────────────────────────────────────────────┘

SESSION="$1"
PROJECT="${2:-$(pwd)}"

# Create session in the project directory
init_layout "$SESSION" "$PROJECT"

# Get the first pane (main workspace)
MAIN=$(tmux list-panes -t "$SESSION" -F '#{pane_id}' | head -1)

# Split: top 70% | bottom 30%
LAZYGIT=$(tmux split-window -v -t "$MAIN" -c "$PROJECT" -p 30 -PF '#{pane_id}')

# Split top pane: left 65% | right 35%
TERMINAL=$(tmux split-window -h -t "$MAIN" -c "$PROJECT" -p 35 -PF '#{pane_id}')

wait_for_panes

# Launch tools in each pane
run_claude "$MAIN"
tmux send-keys -t "$TERMINAL" "" ""
run_lazygit "$LAZYGIT"

# Focus on main pane
tmux select-pane -t "$MAIN"
