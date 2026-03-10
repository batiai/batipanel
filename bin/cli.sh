#!/usr/bin/env bash
# npm/npx entry point — delegates to the installed batipanel or runs installer
set -euo pipefail

BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"

if [ -f "$BATIPANEL_HOME/bin/start.sh" ]; then
  exec bash "$BATIPANEL_HOME/bin/start.sh" "$@"
else
  echo "batipanel is not installed yet. Running installer..."
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  bash "$SCRIPT_DIR/install.sh"
  echo ""
  echo "Run 'batipanel' or 'b' to start."
fi
