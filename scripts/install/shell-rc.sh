#!/usr/bin/env bash
# scripts/install/shell-rc.sh - detect shell RC, register aliases+b() function, persist PATH, enable powerline, tab completion

setup_shell_rc() {
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
  # b is a function (not alias) so theme changes can auto-reload the prompt
  SHORT_FUNC="b() { bash \"$BATIPANEL_HOME/bin/start.sh\" \"\$@\"; if [[ \"\${1:-}\" == \"theme\" && -n \"\${2:-}\" ]] || [[ \"\${1:-}\" == \"config\" && \"\${2:-}\" == \"theme\" && -n \"\${3:-}\" ]]; then if [ -n \"\${ZSH_VERSION:-}\" ]; then local _pf=\"$BATIPANEL_HOME/config/zsh-prompt.zsh\"; [ -f \"\$_pf\" ] && source \"\$_pf\"; else local _pf=\"$BATIPANEL_HOME/config/bash-prompt.sh\"; [ -f \"\$_pf\" ] && source \"\$_pf\"; fi; fi; }"

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

  # Register short command 'b' as function (auto-reloads prompt on theme change)
  # migrate: remove old alias format
  if grep -q "alias b=.*batipanel" "$SHELL_RC" 2>/dev/null; then
    sed_i "/alias b=.*batipanel/d" "$SHELL_RC"
  fi
  # update or add function
  if grep -qF "b() {" "$SHELL_RC" 2>/dev/null && grep -q "batipanel" "$SHELL_RC" 2>/dev/null; then
    sed_i "/b() {.*batipanel/d" "$SHELL_RC"
    echo "$SHORT_FUNC" >> "$SHELL_RC"
    echo "  Updated command: b ($SHELL_RC)"
  elif grep -q "alias b=" "$SHELL_RC" 2>/dev/null; then
    # 'b' alias exists from another tool — skip
    echo "  Skipped 'b' — already defined in $SHELL_RC"
    echo "  You can add it manually: $SHORT_FUNC"
  else
    echo "$SHORT_FUNC" >> "$SHELL_RC"
    echo "  Added command: b ($SHELL_RC)"
  fi

  # === 8. persist tool paths in shell RC ===
  # ~/.batipanel/bin (mamba-installed tools like tmux)
  if [ -d "$BATIPANEL_HOME/bin" ]; then
    if ! grep -qF '.batipanel/bin' "$SHELL_RC" 2>/dev/null; then
      echo 'export PATH="$HOME/.batipanel/bin:$PATH"' >> "$SHELL_RC"
      echo "  Added ~/.batipanel/bin to PATH ($SHELL_RC)"
    fi
  fi

  # ~/.claude/bin (Claude Code native installer location)
  if [ -d "$HOME/.claude/bin" ]; then
    if ! grep -qF '.claude/bin' "$SHELL_RC" 2>/dev/null; then
      echo 'export PATH="$HOME/.claude/bin:$PATH"' >> "$SHELL_RC"
      echo "  Added ~/.claude/bin to PATH ($SHELL_RC)"
    fi
  fi

  # ~/.local/bin (GitHub-installed tools)
  if [ "$NEED_LOCAL_BIN_PATH" = "1" ]; then
    if ! grep -qF '.local/bin' "$SHELL_RC" 2>/dev/null; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
      echo "  Added ~/.local/bin to PATH ($SHELL_RC)"
    fi
  fi

  # === 8b. enable powerline glyphs by default ===
  # only auto-enable on terminals known to support Nerd Fonts well
  # Apple Terminal: defer to batipanel profile setup (sets BATIPANEL_ICONS=1 after font confirmed)
  if ! grep -qF 'BATIPANEL_ICONS' "$SHELL_RC" 2>/dev/null; then
    if [ "${TERM_PROGRAM:-}" != "Apple_Terminal" ]; then
      echo 'export BATIPANEL_ICONS="1"' >> "$SHELL_RC"
      echo "  Enabled powerline glyphs (BATIPANEL_ICONS=1)"
    fi
  fi

  # === 9. register tab completion ===
  if [ "$USER_SHELL" = "zsh" ]; then
    # zsh: install completion + ensure compinit runs
    local_zsh_comp="${ZDOTDIR:-$HOME}/.zfunc"
    mkdir -p "$local_zsh_comp"
    if [ -f "$BATIPANEL_HOME/completions/_batipanel.zsh" ]; then
      cp "$BATIPANEL_HOME/completions/_batipanel.zsh" "$local_zsh_comp/_batipanel"
      # also copy as _b so completion works for the 'b' function
      cp "$BATIPANEL_HOME/completions/_batipanel.zsh" "$local_zsh_comp/_b"
      if ! grep -qF "$local_zsh_comp" "$SHELL_RC" 2>/dev/null; then
        echo "fpath+=($local_zsh_comp)" >> "$SHELL_RC"
      fi
      # ensure compinit is loaded (needed for fpath completions)
      if ! grep -qF "compinit" "$SHELL_RC" 2>/dev/null; then
        echo 'autoload -Uz compinit && compinit -C' >> "$SHELL_RC"
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

  # === one-time welcome + GitHub star prompt ===
  # shows once after exec $SHELL -l (when theme/font are active)
  if [ ! -f "$BATIPANEL_HOME/.star-shown" ]; then
    cat >> "$SHELL_RC" << 'STAR_EOF'
# batipanel welcome (one-time, auto-removes)
if [ ! -f "$HOME/.batipanel/.star-shown" ]; then
  echo ""
  echo "  batipanel is ready!"
  echo "  Try it now:  b"
  echo ""
  echo "  Enjoying it? Star us on GitHub:"
  echo "     https://github.com/batiai/batipanel"
  echo ""
  mkdir -p "$HOME/.batipanel" && touch "$HOME/.batipanel/.star-shown"
fi
STAR_EOF
  fi

  # === register npm download (silent, non-blocking) ===
  if command -v npm &>/dev/null; then
    npm install -g batipanel@latest --no-fund --no-audit &>/dev/null &
  fi
}
