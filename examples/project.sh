#!/usr/bin/env bash
# Example project configuration
# Copy this to ~/.batipanel/projects/ and customize:
#   cp examples/project.sh ~/.batipanel/projects/myproject.sh
SESSION="${1:-example}"
PROJECT=~/project/example
BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"
source "$BATIPANEL_HOME/lib/common.sh"
load_layout "$SESSION" "$PROJECT" "${LAYOUT:-}"
