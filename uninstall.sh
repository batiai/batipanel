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

# 3. remove ALL batipanel lines from shell RC files
for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
  [ -f "$rc" ] || continue
  if grep -qE "(batipanel|\.batipanel)" "$rc" 2>/dev/null; then
    _sed_i '/# batipanel/d' "$rc"
    _sed_i '/alias batipanel=/d' "$rc"
    _sed_i '/alias b=.*batipanel/d' "$rc"
    # b() function (may span one line)
    _sed_i '/b().*batipanel/d' "$rc"
    # prompt source lines
    _sed_i '/bash-prompt\.sh/d' "$rc"
    _sed_i '/zsh-prompt\.zsh/d' "$rc"
    _sed_i '/# batipanel shell theme/d' "$rc"
    _sed_i '/# batipanel prompt theme/d' "$rc"
    # completion lines
    _sed_i '/completions\/batipanel/d' "$rc"
    _sed_i '/_batipanel/d' "$rc"
    # PATH additions
    _sed_i '/\.batipanel\/bin/d' "$rc"
    # clean up blank lines left behind (collapse multiple empty lines to one)
    _sed_i '/^[[:space:]]*$/{ N; /^\n[[:space:]]*$/d; }' "$rc"
    echo "  Cleaned all batipanel entries from $(basename "$rc")"
  fi
done

# remove zsh completion from fpath
local_zsh_comp="${ZDOTDIR:-$HOME}/.zfunc"
rm -f "$local_zsh_comp/_batipanel" "$local_zsh_comp/_b" 2>/dev/null
if [ -d "$local_zsh_comp" ]; then
  echo "  Removed zsh completions from .zfunc"
fi

# 4. stop server containers (if running)
if [ -f "$BATIPANEL_HOME/server/docker-compose.yml" ]; then
  if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    echo "  Stopping server containers..."
    if docker compose version &>/dev/null 2>&1; then
      docker compose -f "$BATIPANEL_HOME/server/docker-compose.yml" down 2>/dev/null || true
    elif command -v docker-compose &>/dev/null; then
      docker-compose -f "$BATIPANEL_HOME/server/docker-compose.yml" down 2>/dev/null || true
    fi
    echo "  Server containers stopped"
  fi
fi

# 5. remove ~/.batipanel/ (preserve projects if user wants)
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
