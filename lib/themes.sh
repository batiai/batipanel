#!/usr/bin/env bash
# batipanel themes - color theme system (orchestrator)
# Sub-modules: themes-data.sh, themes-tmux.sh, themes-bash.sh

# apply theme colors to Apple Terminal via osascript
_apply_apple_terminal_colors() {
  local bg="$1" fg="$2" cursor="$3"
  [[ "$bg" =~ ^# ]] || return 0
  command -v osascript &>/dev/null || return 0

  # convert hex #RRGGBB to AppleScript RGB {R*257, G*257, B*257}
  _hex_to_as_rgb() {
    local hex="${1#\#}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "$((r * 257)), $((g * 257)), $((b * 257))"
  }

  local bg_rgb fg_rgb cursor_rgb
  bg_rgb=$(_hex_to_as_rgb "$bg")
  fg_rgb=$(_hex_to_as_rgb "$fg")
  cursor_rgb=$(_hex_to_as_rgb "$cursor")

  # update batipanel profile if it exists (so new windows also get the colors)
  # then apply to current window for immediate feedback
  osascript <<APPLESCRIPT 2>/dev/null || true
tell application "Terminal"
  if exists settings set "batipanel" then
    set background color of settings set "batipanel" to {${bg_rgb}}
    set normal text color of settings set "batipanel" to {${fg_rgb}}
    set cursor color of settings set "batipanel" to {${cursor_rgb}}
  end if
  -- also apply to current window immediately
  set w to front window
  set background color of current settings of w to {${bg_rgb}}
  set normal text color of current settings of w to {${fg_rgb}}
  set cursor color of current settings of w to {${cursor_rgb}}
end tell
APPLESCRIPT
}

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

  # update theme env file (used by zsh/bash prompts)
  BATIPANEL_THEME="$theme"
  if declare -f generate_theme_env &>/dev/null; then
    generate_theme_env "$theme"
  fi

  # regenerate zsh prompt file with new theme colors
  if declare -f _generate_zsh_prompt &>/dev/null; then
    _generate_zsh_prompt
  fi

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

  # live reload: apply theme overlay to all running tmux servers
  if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null 2>&1; then
    tmux source-file "$BATIPANEL_HOME/config/theme.conf" 2>/dev/null || true
  fi

  # live reload: apply terminal colors immediately
  local term_colors
  term_colors=$(_get_theme_terminal_colors "$theme")
  local bg fg cursor
  read -r bg fg cursor _ <<< "$term_colors"

  if [[ "${TERM_PROGRAM:-}" == "Apple_Terminal" ]]; then
    # Apple Terminal: use osascript instead of OSC sequences
    _apply_apple_terminal_colors "$bg" "$fg" "$cursor"
  else
    # other terminals: OSC 10/11/12
    printf '\e]11;%s\a' "$bg"
    printf '\e]10;%s\a' "$fg"
    printf '\e]12;%s\a' "$cursor"
  fi

  log_info "theme applied: $theme"
  echo -e "${GREEN}Theme applied: ${theme}${NC}"
  echo "  Terminal and prompt colors updated."
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
