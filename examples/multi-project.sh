#!/usr/bin/env bash
# Example: Register and manage multiple projects
#
# Run this script to set up several projects at once:
#   bash examples/multi-project.sh

BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"

# Check if batipanel is installed
if [ ! -f "$BATIPANEL_HOME/bin/start.sh" ]; then
  echo "batipanel is not installed. Run install.sh first."
  exit 1
fi

# Register projects (edit paths to match your setup)
bash "$BATIPANEL_HOME/bin/start.sh" new frontend  ~/projects/frontend
bash "$BATIPANEL_HOME/bin/start.sh" new backend   ~/projects/backend
bash "$BATIPANEL_HOME/bin/start.sh" new infra     ~/projects/infrastructure

echo ""
echo "Projects registered! Start any with:"
echo "  b frontend"
echo "  b backend"
echo "  b infra"
echo ""
echo "List all: b ls"
