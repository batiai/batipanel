#!/usr/bin/env bash
# batipanel themes - color theme system (orchestrator)
# Sub-modules: themes-data.sh, themes-tmux.sh, themes-bash.sh

# apply theme: generate files, persist config, live reload
# shellcheck disable=SC2153  # BATIPANEL_HOME is set by core.sh
_apply_theme() {
  local theme="$1"

  # validate theme exists
  if ! _get_theme_colors "$theme" >/dev/null 2>&1; then
    echo -e "${RED}Unknown theme: ${theme}${NC}"
    _list_themes
    return 1
  fi

  # generate tmux theme overlay
  _generate_theme_conf "$theme"

  # generate themed bash prompt
  _generate_themed_prompt "$theme"

  # persist to config.sh
  if [ -f "$TMUX_CONFIG" ]; then
    if grep -qF "BATIPANEL_THEME=" "$TMUX_CONFIG"; then
      _sed_i "s|BATIPANEL_THEME=.*|BATIPANEL_THEME=\"$theme\"|" "$TMUX_CONFIG"
    else
      echo "BATIPANEL_THEME=\"$theme\"" >> "$TMUX_CONFIG"
    fi
  else
    echo "BATIPANEL_THEME=\"$theme\"" > "$TMUX_CONFIG"
  fi

  # update zsh prompt terminal colors
  local zsh_prompt="$BATIPANEL_HOME/config/zsh-prompt.zsh"
  if [ -f "$zsh_prompt" ]; then
    local term_colors
    term_colors=$(_get_theme_terminal_colors "$theme")
    local bg fg cursor
    bg=$(echo "$term_colors" | awk '{print $1}')
    fg=$(echo "$term_colors" | awk '{print $2}')
    cursor=$(echo "$term_colors" | awk '{print $3}')
    _sed_i "s|printf '\\\\e\]11;#[0-9a-f]*\\\\a'|printf '\\\\e]11;${bg}\\\\a'|" "$zsh_prompt"
    _sed_i "s|printf '\\\\e\]10;#[0-9a-f]*\\\\a'|printf '\\\\e]10;${fg}\\\\a'|" "$zsh_prompt"
    _sed_i "s|printf '\\\\e\]12;#[0-9a-f]*\\\\a'|printf '\\\\e]12;${cursor}\\\\a'|" "$zsh_prompt"
  fi

  # live reload: apply theme overlay to all running tmux servers
  if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null 2>&1; then
    tmux source-file "$BATIPANEL_HOME/config/theme.conf" 2>/dev/null || true
  fi

  # live reload: apply terminal colors to current shell immediately
  local term_colors
  term_colors=$(_get_theme_terminal_colors "$theme")
  local bg fg cursor
  bg=$(echo "$term_colors" | awk '{print $1}')
  fg=$(echo "$term_colors" | awk '{print $2}')
  cursor=$(echo "$term_colors" | awk '{print $3}')
  printf '\e]11;%s\a' "$bg"
  printf '\e]10;%s\a' "$fg"
  printf '\e]12;%s\a' "$cursor"

  BATIPANEL_THEME="$theme"
  log_info "theme applied: $theme"
  echo -e "${GREEN}Theme applied: ${theme}${NC}"
}

# CLI entry point: b theme [name]
tmux_theme() {
  local name="${1:-}"

  case "$name" in
    ""|list)
      echo -e "  Current theme: ${GREEN}${BATIPANEL_THEME:-default}${NC}"
      _list_themes
      echo "  Change: b theme <name>"
      ;;
    *)
      _apply_theme "$name"
      ;;
  esac
}
