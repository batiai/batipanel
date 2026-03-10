#!/usr/bin/env bash
# batipanel layout - DevOps/infrastructure monitoring workspace
#
# Optimized for server management, Docker, and log monitoring.
#
# ┌──────────────────┬──────────────────┐
# │                  │                  │
# │  claude          │  btop            │
# │                  │                  │
# ├──────────────────┼──────────────────┤
# │  lazydocker      │  terminal        │
# │                  │  (kubectl, etc.) │
# ├──────────────────┴──────────────────┤
# │  logs — full width (docker logs)    │
# └─────────────────────────────────────┘

SESSION="$1"
PROJECT="${2:-$(pwd)}"

init_layout "$SESSION" "$PROJECT"

CLAUDE=$(tmux list-panes -t "$SESSION" -F '#{pane_id}' | head -1)

# Bottom log bar (25%)
LOGS=$(_split -v -t "$CLAUDE" -c "$PROJECT" -p 25 -PF '#{pane_id}')

# Upper area: top(60%) | middle(40%)
DOCKER=$(_split -v -t "$CLAUDE" -c "$PROJECT" -p 40 -PF '#{pane_id}')

# Top: left(50%) | right(50%)
BTOP=$(_split -h -t "$CLAUDE" -c "$PROJECT" -p 50 -PF '#{pane_id}')

# Middle: left(50%) | right(50%)
ZSH=$(_split -h -t "$DOCKER" -c "$PROJECT" -p 50 -PF '#{pane_id}')

wait_for_panes

run_claude "$CLAUDE"
run_monitor "$BTOP"
run_lazydocker "$DOCKER"
label_pane "$ZSH" "Shell"
tmux send-keys -t "$ZSH" "" ""
label_pane "$LOGS" "Logs"
tmux send-keys -t "$LOGS" "echo 'Logs — docker compose logs -f, tail -f, stern, etc.'" Enter

tmux select-pane -t "$CLAUDE"
