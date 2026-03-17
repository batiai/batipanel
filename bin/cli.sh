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
  echo -e "  \033[2m───────────────────────────────────\033[0m"
  echo -e "  \033[1mNext step\033[0m \033[2m— activate your shell:\033[0m"
  echo ""
  echo -e "    \033[36mexec \$SHELL -l\033[0m"
  echo ""
  echo -e "  \033[2mor just open a new terminal window.\033[0m"
  echo -e "  \033[2m───────────────────────────────────\033[0m"
fi
