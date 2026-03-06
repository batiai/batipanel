#!/usr/bin/env bash
# ~/tmux/example.sh - Example project configuration
# Copy this file and change SESSION and PROJECT to create your own:
#   cp ~/tmux/example.sh ~/tmux/myproject.sh
SESSION="${1:-example}"
PROJECT=~/project/example
source ~/tmux/common.sh
load_layout "$SESSION" "$PROJECT" "${LAYOUT:-}"
