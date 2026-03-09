#!/usr/bin/env bash
# batipanel diagnostics - system health check

tmux_doctor() {
  local ok="${GREEN}OK${NC}"
  local warn="${YELLOW}WARN${NC}"
  local fail="${RED}FAIL${NC}"
  local issues=0

  echo ""
  echo -e "${BLUE}=== batipanel doctor ===${NC}"
  echo ""

  # 1. tmux
  if command -v tmux &>/dev/null; then
    local ver
    ver=$(tmux -V 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
    local major="${ver%%.*}" minor="${ver#*.}"
    if [[ -n "$ver" ]] && (( major >= 2 && (major > 2 || minor >= 6) )); then
      echo -e "  [$ok]  tmux $ver"
    else
      echo -e "  [$fail]  tmux ${ver:-unknown} (need 2.6+)"
      issues=$((issues + 1))
    fi
  else
    echo -e "  [$fail]  tmux not installed"
    issues=$((issues + 1))
  fi

  # 2. optional tools
  local tools=("claude:Claude Code" "lazygit:lazygit" "btop:btop" "yazi:yazi" "eza:eza")
  for entry in "${tools[@]}"; do
    local cmd="${entry%%:*}" name="${entry#*:}"
    if command -v "$cmd" &>/dev/null; then
      echo -e "  [$ok]  $name"
    elif [ -x "$HOME/.local/bin/$cmd" ]; then
      echo -e "  [$warn]  $name found at ~/.local/bin/$cmd but NOT in PATH"
      echo "          Fix: add 'export PATH=\"\$HOME/.local/bin:\$PATH\"' to your shell config"
      issues=$((issues + 1))
    else
      echo -e "  [$warn]  $name not installed (optional)"
    fi
  done

  # 3. fallback chain
  if ! command -v btop &>/dev/null; then
    if command -v htop &>/dev/null; then
      echo -e "  [${ok}]  monitor fallback: htop"
    elif command -v top &>/dev/null; then
      echo -e "  [${ok}]  monitor fallback: top"
    else
      echo -e "  [$warn]  no system monitor found"
    fi
  fi

  # 4. batipanel install
  echo ""
  if [ -f "$BATIPANEL_HOME/lib/common.sh" ]; then
    local installed_ver
    installed_ver=$(cat "$BATIPANEL_HOME/VERSION" 2>/dev/null || echo "unknown")
    echo -e "  [$ok]  batipanel v$installed_ver installed at $BATIPANEL_HOME"
  else
    echo -e "  [$fail]  batipanel not properly installed"
    issues=$((issues + 1))
  fi

  # 5. config
  if [ -f "$TMUX_CONFIG" ]; then
    echo -e "  [$ok]  config: $DEFAULT_LAYOUT layout"
  else
    echo -e "  [$warn]  no config.sh (run 'b' to set up)"
  fi

  # 6. projects
  local proj_count=0
  for f in "$BATIPANEL_HOME"/projects/*.sh; do
    [ -f "$f" ] && proj_count=$((proj_count + 1))
  done
  if (( proj_count > 0 )); then
    echo -e "  [$ok]  $proj_count project(s) registered"
  else
    echo -e "  [$warn]  no projects (run 'b new <name> <path>')"
  fi

  # 7. tmux.conf
  if [ -f "$HOME/.tmux.conf" ] && grep -q "batipanel" "$HOME/.tmux.conf" 2>/dev/null; then
    echo -e "  [$ok]  ~/.tmux.conf configured"
  else
    echo -e "  [$warn]  ~/.tmux.conf missing batipanel source line"
    echo "          Fix: echo 'source-file ~/.batipanel/config/tmux.conf' >> ~/.tmux.conf"
  fi

  # 8. shell alias
  local rc_found=0
  for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
    if [ -f "$rc" ] && grep -q "batipanel" "$rc" 2>/dev/null; then
      echo -e "  [$ok]  alias registered in $(basename "$rc")"
      rc_found=1
      break
    fi
  done
  if (( rc_found == 0 )); then
    echo -e "  [$warn]  no shell alias found"
    echo "          Fix: echo \"alias b='bash $BATIPANEL_HOME/bin/start.sh'\" >> ~/.zshrc"
  fi

  # 9. tab completion
  local comp_found=0
  for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
    if [ -f "$rc" ] && grep -q "completions/batipanel" "$rc" 2>/dev/null; then
      comp_found=1
      break
    fi
  done
  if (( comp_found == 1 )); then
    echo -e "  [$ok]  tab completion enabled"
  else
    echo -e "  [$warn]  tab completion not enabled"
    echo "          Fix: re-run install.sh or source ~/.batipanel/completions/batipanel.bash"
  fi

  # summary
  echo ""
  if (( issues == 0 )); then
    echo -e "  ${GREEN}All good!${NC}"
  else
    echo -e "  ${RED}$issues issue(s) found${NC}"
  fi
  echo ""
}
