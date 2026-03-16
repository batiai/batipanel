#!/usr/bin/env bash
# install.sh - batipanel installer (macOS / Linux)
# Orchestrator: sources modular scripts from scripts/install/

set -euo pipefail

BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"

echo "batipanel - Setting up AI development workspace..."

# detect OS
OS="$(uname -s)"

# resolve installer directory (before sourcing modules that use SCRIPT_DIR)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shared state: modified by utils.sh install_from_github()
NEED_LOCAL_BIN_PATH=0

# source modules
# shellcheck source=scripts/install/utils.sh
source "$SCRIPT_DIR/scripts/install/utils.sh"
# shellcheck source=scripts/install/tools.sh
source "$SCRIPT_DIR/scripts/install/tools.sh"
# shellcheck source=scripts/install/files.sh
source "$SCRIPT_DIR/scripts/install/files.sh"
# shellcheck source=scripts/install/tmux-config.sh
source "$SCRIPT_DIR/scripts/install/tmux-config.sh"
# shellcheck source=scripts/install/shell-rc.sh
source "$SCRIPT_DIR/scripts/install/shell-rc.sh"
# shellcheck source=scripts/install/fonts.sh
source "$SCRIPT_DIR/scripts/install/fonts.sh"

# === 1. install tools ===
setup_install_paths
install_required_tools
install_optional_tools

# === 2-5. copy files and completions ===
copy_files
install_completions

# === 6. tmux config ===
setup_tmux_config

# === 7-9. shell RC, PATH, completions ===
setup_shell_rc

# === 9b. fonts and terminal profile ===
setup_fonts_and_terminal

# === 10. setup shell environment (powerline fonts, prompt theme) ===
# _sed_i is needed by shell-setup.sh (reuse install.sh's sed_i)
_sed_i() { sed_i "$@"; }
export -f _sed_i 2>/dev/null || true

# source theme modules so _generate_themed_prompt is available
# shellcheck source=lib/core.sh
source "$BATIPANEL_HOME/lib/core.sh"
# shellcheck source=lib/themes-data.sh
source "$BATIPANEL_HOME/lib/themes-data.sh"
# shellcheck source=lib/themes-tmux.sh
source "$BATIPANEL_HOME/lib/themes-tmux.sh"
# shellcheck source=lib/themes-bash.sh
source "$BATIPANEL_HOME/lib/themes-bash.sh"
# shellcheck source=lib/shell-setup.sh
source "$BATIPANEL_HOME/lib/shell-setup.sh"

# apply default theme (generates theme.conf, bash-prompt.sh, theme-env.sh)
BATIPANEL_THEME="${BATIPANEL_THEME:-default}"
_generate_theme_conf "$BATIPANEL_THEME"
generate_theme_env "$BATIPANEL_THEME"

# setup shell RC (sources prompt file from .bashrc/.zshrc)
setup_shell_environment "$USER_SHELL" "$SHELL_RC"

# === done ===
echo ""
echo "batipanel installed successfully!"
echo "  Location: $BATIPANEL_HOME"
echo ""

# Report missing tools
if ! command -v claude &>/dev/null; then
  echo "WARNING: Claude Code is not installed (core dependency)"
  echo "  Install: curl -fsSL https://claude.ai/install.sh | bash"
  echo ""
fi

MISSING=()
command -v lazygit &>/dev/null || MISSING+=("lazygit")
command -v btop &>/dev/null   || MISSING+=("btop")
command -v yazi &>/dev/null   || MISSING+=("yazi")
command -v eza &>/dev/null    || MISSING+=("eza")
if [ ${#MISSING[@]} -gt 0 ]; then
  echo "Optional tools not installed (will work without them):"
  for m in "${MISSING[@]}"; do
    echo "  - $m"
  done
  if [[ "$(uname -s)" == "Linux" ]] && command -v apt-get &>/dev/null; then
    echo ""
    echo "  On Ubuntu/Debian, some tools need manual installation:"
    echo "    lazygit: https://github.com/jesseduffield/lazygit#installation"
    echo "    yazi:    https://github.com/sxyazi/yazi#installation"
    echo "    eza:     https://github.com/eza-community/eza#installation"
  fi
  echo ""
fi

echo "Usage:"
echo "  b myproject                  # Start or resume a project"
echo "  b myproject --layout 6panel  # Start with specific layout"
echo "  b new <name> <path>          # Register a new project"
echo "  b stop myproject             # Stop a session"
echo "  b ls                         # List sessions & projects"
echo "  b layouts                    # Show available layouts"
echo "  b config layout 7panel       # Change default layout"
echo "  b theme                      # List/change color themes"
echo ""
if [ "${TERM_PROGRAM:-}" = "Apple_Terminal" ]; then
  echo "Apple Terminal: using 'batipanel' profile with Nerd Font + theme colors."
  echo ""
  echo "Type: b"
  echo ""
  echo "Tip: For the best experience (true color, native tabs), try iTerm2:"
  if [ ! -d "/Applications/iTerm.app" ]; then
    if command -v brew &>/dev/null; then
      echo "  brew install --cask iterm2"
    else
      echo "  https://iterm2.com/downloads.html"
    fi
  else
    echo "  iTerm2 is already installed — open it and type: b"
  fi
else
  echo "Tip: Set your terminal font to a Nerd Font (e.g. MesloLGS NF)"
  echo "     for powerline arrow-style prompt glyphs."
  echo ""
  echo "Type: b"
fi

# === activate prompt theme ===
# don't exec $SHELL — it breaks /dev/tty when run from curl|bash or subshells
if [ -z "${npm_lifecycle_event:-}" ]; then
  echo ""
  echo -e "  \033[2m───────────────────────────────────\033[0m"
  echo -e "  \033[1mNext step\033[0m \033[2m— activate your shell:\033[0m"
  echo ""
  echo -e "    \033[36mexec \$SHELL -l\033[0m"
  echo ""
  echo -e "  \033[2mor just open a new terminal window.\033[0m"
  echo -e "  \033[2m───────────────────────────────────\033[0m"
fi
