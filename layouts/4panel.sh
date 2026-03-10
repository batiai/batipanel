#!/usr/bin/env bash
# batipanel layout - Minimal 4-panel workspace
#
# ┌────────────────────────┬──────────────────┐
# │                        │                  │
# │  claude (main)         │  btop            │
# │  60% width, 65% height│                  │
# │                        │                  │
# ├────────────────────────┼──────────────────┤
# │  lazygit               │  terminal        │
# └────────────────────────┴──────────────────┘

SESSION="$1"
PROJECT="${2:-$(pwd)}"

init_layout "$SESSION" "$PROJECT"

CLAUDE=$(tmux list-panes -t "$SESSION" -F '#{pane_id}' | head -1)

# Top(65%) | Bottom(35%)
LAZYGIT=$(_split -v -t "$CLAUDE" -c "$PROJECT" -p 35 -PF '#{pane_id}')

# Top: left(60%) | right(40%)
BTOP=$(_split -h -t "$CLAUDE" -c "$PROJECT" -p 40 -PF '#{pane_id}')

# Bottom: left(55%) | right(45%)
ZSH=$(_split -h -t "$LAZYGIT" -c "$PROJECT" -p 45 -PF '#{pane_id}')

wait_for_panes

run_claude "$CLAUDE"
run_monitor "$BTOP"
run_lazygit "$LAZYGIT"
tmux send-keys -t "$ZSH" "" ""

tmux select-pane -t "$CLAUDE"
