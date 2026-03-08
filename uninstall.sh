#!/usr/bin/env bash
# uninstall.sh - remove batipanel configuration and aliases

set -euo pipefail

BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"

if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' NC=''
fi

echo ""
echo -e "${RED}batipanel uninstaller${NC}"
echo ""

# portable sed -i
_sed_i() {
  if [ "$(uname -s)" = "Darwin" ]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# 1. stop active sessions
if command -v tmux &>/dev/null; then
  for f in "$BATIPANEL_HOME"/projects/*.sh; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .sh)
    if tmux has-session -t "$name" 2>/dev/null; then
      tmux kill-session -t "$name" 2>/dev/null || true
      echo "  Stopped session: $name"
    fi
  done
fi

# 2. remove tmux.conf source line
if [ -f "$HOME/.tmux.conf" ]; then
  if grep -q "batipanel" "$HOME/.tmux.conf" 2>/dev/null; then
    _sed_i '/# batipanel/d' "$HOME/.tmux.conf"
    _sed_i '/batipanel/d' "$HOME/.tmux.conf"
    echo "  Cleaned ~/.tmux.conf"
  fi
fi

# 3. remove shell aliases and completion source lines
for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
  [ -f "$rc" ] || continue
  if grep -q "batipanel" "$rc" 2>/dev/null; then
    _sed_i '/# batipanel/d' "$rc"
    _sed_i '/alias batipanel=/d' "$rc"
    _sed_i '/alias b=.*batipanel/d' "$rc"
    _sed_i '/completions\/batipanel/d' "$rc"
    echo "  Cleaned aliases and completions from $(basename "$rc")"
  fi
done

# remove zsh completion from fpath
local_zsh_comp="${ZDOTDIR:-$HOME}/.zfunc"
if [ -f "$local_zsh_comp/_batipanel" ]; then
  rm -f "$local_zsh_comp/_batipanel"
  echo "  Removed zsh completion"
fi

# 4. remove ~/.batipanel/ (preserve projects if user wants)
if [ -d "$BATIPANEL_HOME" ]; then
  project_count=0
  for f in "$BATIPANEL_HOME"/projects/*.sh; do
    [ -f "$f" ] && project_count=$((project_count + 1))
  done

  if (( project_count > 0 )) && [ -t 0 ]; then
    echo ""
    echo -e "${YELLOW}You have $project_count registered project(s).${NC}"
    printf "Keep project configs in %s/projects/? [Y/n] " "$BATIPANEL_HOME"
    read -r keep_projects
    if [[ "$keep_projects" == [nN] ]]; then
      rm -rf "$BATIPANEL_HOME"
      echo "  Removed $BATIPANEL_HOME (including projects)"
    else
      # remove everything except projects/
      find "$BATIPANEL_HOME" -mindepth 1 -maxdepth 1 ! -name projects -exec rm -rf {} +
      echo "  Removed $BATIPANEL_HOME (kept projects/)"
    fi
  else
    rm -rf "$BATIPANEL_HOME"
    echo "  Removed $BATIPANEL_HOME"
  fi
fi

echo ""
echo -e "${GREEN}batipanel uninstalled.${NC}"
echo "  Open a new terminal to apply changes."
echo ""
