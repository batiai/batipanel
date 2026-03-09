#!/usr/bin/env bash
# install.sh - batipanel installer (macOS / Linux)

set -euo pipefail

BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"

echo "batipanel - Setting up AI development workspace..."

# detect OS
OS="$(uname -s)"

# portable sed -i (macOS vs GNU)
sed_i() {
  if [ "$OS" = "Darwin" ]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# === 1. detect package manager and install tools ===
echo ""
echo "Checking tools..."

install_packages() {
  local packages=("$@")

  if command -v brew &>/dev/null; then
    brew install "${packages[@]}" 2>/dev/null || true
  elif command -v apt-get &>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq "${packages[@]}" 2>/dev/null || true
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y "${packages[@]}" 2>/dev/null || true
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm "${packages[@]}" 2>/dev/null || true
  else
    echo "No package manager found."
    echo "Please install manually: ${packages[*]}"
    return 1
  fi
}

# required: tmux
if ! command -v tmux &>/dev/null; then
  echo "Installing tmux..."
  install_packages tmux || {
    echo ""
    echo "Failed to install tmux. Please install manually:"
    case "$OS" in
      Darwin) echo "  brew install tmux" ;;
      *)
        echo "  Ubuntu/Debian: sudo apt install tmux"
        echo "  Fedora:        sudo dnf install tmux"
        echo "  Arch:          sudo pacman -S tmux"
        ;;
    esac
    exit 1
  }
fi

if ! command -v tmux &>/dev/null; then
  echo "tmux installation failed."
  exit 1
fi

# optional: lazygit, eza, btop (works without them)
echo ""
echo "Installing optional tools (will work without them)..."

# lazygit
if ! command -v lazygit &>/dev/null; then
  install_packages lazygit 2>/dev/null || true
fi

# btop
if ! command -v btop &>/dev/null; then
  install_packages btop 2>/dev/null || true
fi

# yazi
if ! command -v yazi &>/dev/null; then
  install_packages yazi 2>/dev/null || true
fi

# eza
if ! command -v eza &>/dev/null; then
  install_packages eza 2>/dev/null || true
fi

# === 2. create directory structure ===
mkdir -p "$BATIPANEL_HOME"/{bin,lib,layouts,projects,config}

# === 3. migrate existing ~/tmux/ ===
if [ -d "$HOME/tmux" ] && [ ! -f "$BATIPANEL_HOME/.migrated" ]; then
  echo ""
  echo "Migrating existing ~/tmux/ configuration..."

  # move project files (skip core/layout/example)
  for f in "$HOME"/tmux/*.sh; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .sh)
    case "$name" in
      common|start|layout_*|example) continue ;;
    esac
    if [ ! -f "$BATIPANEL_HOME/projects/$name.sh" ]; then
      cp "$f" "$BATIPANEL_HOME/projects/$name.sh"
      echo "  Migrated project: $name"
    fi
  done

  # update paths in migrated project files
  for f in "$BATIPANEL_HOME"/projects/*.sh; do
    [ -f "$f" ] || continue
    # shellcheck disable=SC2016
    sed_i 's|source ~/tmux/common.sh|BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"\nsource "$BATIPANEL_HOME/lib/common.sh"|g' "$f"
  done

  # preserve existing config.sh
  if [ -f "$HOME/tmux/config.sh" ] && [ ! -f "$BATIPANEL_HOME/config.sh" ]; then
    cp "$HOME/tmux/config.sh" "$BATIPANEL_HOME/config.sh"
    echo "  Preserved config: config.sh"
  fi

  touch "$BATIPANEL_HOME/.migrated"
  echo "  Migration complete"
fi

# === 4. copy scripts ===
echo ""
echo "Installing scripts..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cp "$SCRIPT_DIR/bin/start.sh" "$BATIPANEL_HOME/bin/"
for mod in common.sh core.sh validate.sh layout.sh session.sh project.sh doctor.sh wizard.sh; do
  cp "$SCRIPT_DIR/lib/$mod" "$BATIPANEL_HOME/lib/"
done
cp "$SCRIPT_DIR/VERSION" "$BATIPANEL_HOME/VERSION" 2>/dev/null || true
cp "$SCRIPT_DIR/uninstall.sh" "$BATIPANEL_HOME/" 2>/dev/null || true

for layout in 4panel 5panel 6panel 7panel 7panel_log 8panel dual-claude devops; do
  cp "$SCRIPT_DIR/layouts/${layout}.sh" "$BATIPANEL_HOME/layouts/"
done

chmod +x "$BATIPANEL_HOME"/bin/*.sh "$BATIPANEL_HOME"/lib/*.sh "$BATIPANEL_HOME"/layouts/*.sh

# copy examples
if [ -d "$SCRIPT_DIR/examples" ]; then
  mkdir -p "$BATIPANEL_HOME/examples"
  cp "$SCRIPT_DIR/examples/"*.sh "$BATIPANEL_HOME/examples/" 2>/dev/null || true
fi

# === 5. install completions ===
if [ -d "$SCRIPT_DIR/completions" ]; then
  mkdir -p "$BATIPANEL_HOME/completions"
  cp "$SCRIPT_DIR/completions/batipanel.bash" "$BATIPANEL_HOME/completions/" 2>/dev/null || true
  cp "$SCRIPT_DIR/completions/_batipanel.zsh" "$BATIPANEL_HOME/completions/" 2>/dev/null || true
fi

# === 6. install tmux.conf ===
mkdir -p "$BATIPANEL_HOME/config"
cp "$SCRIPT_DIR/config/tmux.conf" "$BATIPANEL_HOME/config/tmux.conf"

BATIPANEL_SOURCE_LINE="source-file $BATIPANEL_HOME/config/tmux.conf"
if [ -f ~/.tmux.conf ]; then
  if ! grep -qF "$BATIPANEL_SOURCE_LINE" ~/.tmux.conf 2>/dev/null; then
    {
      echo ""
      echo "# batipanel"
      echo "$BATIPANEL_SOURCE_LINE"
    } >> ~/.tmux.conf
    echo "  Added batipanel source line to ~/.tmux.conf"
  else
    echo "  ~/.tmux.conf already configured"
  fi
else
  echo "# batipanel" > ~/.tmux.conf
  echo "$BATIPANEL_SOURCE_LINE" >> ~/.tmux.conf
  echo "  Created ~/.tmux.conf with batipanel source"
fi

# === 7. register aliases ===
# detect user's login shell via $SHELL (not $BASH_VERSION which reflects the script interpreter)
USER_SHELL="$(basename "${SHELL:-/bin/bash}")"
case "$USER_SHELL" in
  zsh)
    SHELL_RC="$HOME/.zshrc"
    ;;
  bash)
    if [ -f "$HOME/.bashrc" ]; then
      SHELL_RC="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
      SHELL_RC="$HOME/.bash_profile"
    else
      SHELL_RC="$HOME/.profile"
    fi
    ;;
  *)
    # fallback: check which RC files exist
    if [ -f "$HOME/.zshrc" ]; then
      SHELL_RC="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
      SHELL_RC="$HOME/.bashrc"
    else
      SHELL_RC="$HOME/.profile"
    fi
    ;;
esac

BATIPANEL_ALIAS="alias batipanel='bash \"$BATIPANEL_HOME/bin/start.sh\"'"
SHORT_ALIAS="alias b='bash \"$BATIPANEL_HOME/bin/start.sh\"'"

# Always register 'batipanel' alias
if grep -q "alias batipanel=" "$SHELL_RC" 2>/dev/null; then
  sed_i "s|alias batipanel=.*|$BATIPANEL_ALIAS|" "$SHELL_RC"
else
  {
    echo ""
    echo "# batipanel - AI workspace manager"
    echo "$BATIPANEL_ALIAS"
  } >> "$SHELL_RC"
fi
echo "  Added alias: batipanel ($SHELL_RC)"

# Register short alias 'b' if no conflict
if grep -q "alias b=" "$SHELL_RC" 2>/dev/null; then
  if grep -q "batipanel" "$SHELL_RC" && grep -q "alias b=.*batipanel" "$SHELL_RC" 2>/dev/null; then
    sed_i "s|alias b=.*|$SHORT_ALIAS|" "$SHELL_RC"
    echo "  Updated alias: b ($SHELL_RC)"
  else
    echo "  Skipped alias 'b' — already defined in $SHELL_RC"
    echo "  You can add it manually: $SHORT_ALIAS"
  fi
else
  echo "$SHORT_ALIAS" >> "$SHELL_RC"
  echo "  Added alias: b ($SHELL_RC)"
fi

# === 8. register tab completion ===
if [ "$USER_SHELL" = "zsh" ]; then
  # zsh: install via fpath (not bash source)
  local_zsh_comp="${ZDOTDIR:-$HOME}/.zfunc"
  mkdir -p "$local_zsh_comp"
  if [ -f "$BATIPANEL_HOME/completions/_batipanel.zsh" ]; then
    cp "$BATIPANEL_HOME/completions/_batipanel.zsh" "$local_zsh_comp/_batipanel"
    if ! grep -qF "$local_zsh_comp" "$SHELL_RC" 2>/dev/null; then
      echo "fpath+=($local_zsh_comp)" >> "$SHELL_RC"
    fi
    echo "  Added zsh completion"
  fi
else
  # bash: source completion script
  COMP_SOURCE="source \"$BATIPANEL_HOME/completions/batipanel.bash\""
  if [ -f "$BATIPANEL_HOME/completions/batipanel.bash" ]; then
    if ! grep -qF "completions/batipanel" "$SHELL_RC" 2>/dev/null; then
      echo "$COMP_SOURCE" >> "$SHELL_RC"
      echo "  Added tab completion ($SHELL_RC)"
    fi
  fi
fi

# === done ===
echo ""
echo "batipanel installed successfully!"
echo "  Location: $BATIPANEL_HOME"
echo ""

# Report missing optional tools
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
  # show install links for tools not in default repos
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
echo ""
echo "Open a new terminal or run: source $SHELL_RC"
