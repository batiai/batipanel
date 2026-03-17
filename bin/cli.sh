#!/usr/bin/env bash
# npm/npx entry point — delegates to the installed batipanel or runs installer
set -euo pipefail

BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -f "$BATIPANEL_HOME/bin/start.sh" ]; then
  # not installed yet (manual run without postinstall)
  echo "batipanel is not installed yet. Running installer..."
  bash "$SCRIPT_DIR/install.sh"
fi

# check if postinstall just ran (flag file created by install.sh under npm)
if [ -f "$BATIPANEL_HOME/.just-installed" ]; then
  rm -f "$BATIPANEL_HOME/.just-installed"
  echo ""
  echo -e "  \033[2m───────────────────────────────────\033[0m"
  echo -e "  \033[1mNext step\033[0m \033[2m— activate your shell:\033[0m"
  echo ""
  echo -e "    \033[36mexec \$SHELL -l\033[0m"
  echo ""
  echo -e "  \033[2mor just open a new terminal window.\033[0m"
  echo -e "  \033[2m───────────────────────────────────\033[0m"
else
  exec bash "$BATIPANEL_HOME/bin/start.sh" "$@"
fi
