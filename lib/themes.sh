#!/usr/bin/env bash
# batipanel themes - color theme system

# available themes
BATIPANEL_THEMES="default dracula nord gruvbox tokyo-night catppuccin rose-pine kanagawa"

# get all theme colors as space-separated values
# usage: _get_theme_colors <theme>
# returns: STATUS_BG STATUS_FG ACCENT ACCENT_FG WINDOW_BG WINDOW_FG
#          WINDOW_ACTIVE_BG WINDOW_ACTIVE_FG BORDER MESSAGE_BG MESSAGE_FG
#          PROMPT_USER_BG PROMPT_DIR_BG PROMPT_GIT_BG PROMPT_ERR_BG
_get_theme_colors() {
  local theme="$1"
  case "$theme" in
    default)
      echo "colour234 colour137 colour2 colour232 colour238 colour249 colour33 colour255 colour240 colour33 colour255 44 240 42 41"
      ;;
    dracula)
      echo "colour236 colour253 colour141 colour232 colour238 colour253 colour212 colour255 colour61 colour141 colour232 105 238 212 203"
      ;;
    nord)
      echo "colour236 colour253 colour110 colour232 colour238 colour253 colour67 colour255 colour240 colour67 colour255 67 238 110 131"
      ;;
    gruvbox)
      echo "colour235 colour223 colour208 colour232 colour237 colour223 colour214 colour235 colour239 colour208 colour235 172 239 142 167"
      ;;
    tokyo-night)
      echo "colour234 colour253 colour111 colour232 colour238 colour253 colour141 colour255 colour240 colour111 colour232 111 238 141 203"
      ;;
    catppuccin)
      echo "colour234 colour189 colour183 colour233 colour237 colour146 colour183 colour233 colour239 colour237 colour189 183 237 151 211"
      ;;
    rose-pine)
      echo "colour234 colour189 colour181 colour234 colour236 colour103 colour181 colour234 colour238 colour235 colour189 182 238 152 168"
      ;;
    kanagawa)
      echo "colour235 colour187 colour110 colour234 colour236 colour242 colour110 colour234 colour59 colour236 colour187 103 236 107 203"
      ;;
    *)
      return 1
      ;;
  esac
}

# theme description for display
_get_theme_desc() {
  case "$1" in
    default)     echo "Green/blue (original)" ;;
    dracula)     echo "Purple/pink dark theme" ;;
    nord)        echo "Arctic blue palette" ;;
    gruvbox)     echo "Retro warm colors" ;;
    tokyo-night) echo "Blue/purple night theme" ;;
    catppuccin)  echo "Pastel warm dark (Mocha)" ;;
    rose-pine)   echo "Soho vibes, warm rose" ;;
    kanagawa)    echo "Japanese ink painting" ;;
  esac
}

# list available themes
_list_themes() {
  local current="${BATIPANEL_THEME:-default}"
  echo ""
  echo -e "  ${BLUE}Available themes:${NC}"
  echo ""
  local name desc marker
  for name in $BATIPANEL_THEMES; do
    desc=$(_get_theme_desc "$name")
    # pad name to 14 chars for alignment
    local padded
    padded=$(printf '%-14s' "$name")
    if [ "$name" = "$current" ]; then
      marker="${GREEN}*${NC}"
      echo -e "    ${marker} ${GREEN}${padded}${NC}${desc}"
    else
      echo -e "      ${padded}${desc}"
    fi
  done
  echo ""
}

# generate tmux theme overlay file
# shellcheck disable=SC2153  # BATIPANEL_HOME is set by core.sh
_generate_theme_conf() {
  local theme="$1"
  local conf_file="$BATIPANEL_HOME/config/theme.conf"

  local colors
  colors=$(_get_theme_colors "$theme") || return 1

  # parse color values
  local status_bg status_fg accent accent_fg win_bg win_fg
  local win_active_bg win_active_fg border msg_bg msg_fg
  # shellcheck disable=SC2086
  read -r status_bg status_fg accent accent_fg win_bg win_fg \
    win_active_bg win_active_fg border msg_bg msg_fg \
    _prompt_user _prompt_dir _prompt_git _prompt_err <<< $colors

  mkdir -p "$BATIPANEL_HOME/config"
  cat > "$conf_file" << CONF
# batipanel theme: ${theme} (auto-generated — do not edit)

# status bar
set -g status-style "bg=${status_bg},fg=${status_fg}"
set -g status-left '#[fg=${accent_fg},bg=${accent},bold]  #S #[fg=${accent},bg=${status_bg},nobold] '
set -g status-right '#[fg=${border},bg=${status_bg}]#[fg=${win_fg},bg=${border}] #{session_windows}W #{window_panes}P #[fg=${accent},bg=${border}]#[fg=${accent_fg},bg=${accent},bold] %H:%M  %m-%d '

# window tabs
setw -g window-status-format '#[fg=${status_bg},bg=${win_bg}]#[fg=${win_fg},bg=${win_bg}] #I #W #[fg=${win_bg},bg=${status_bg}]'
setw -g window-status-current-format '#[fg=${status_bg},bg=${win_active_bg}]#[fg=${win_active_fg},bg=${win_active_bg},bold] #I #W #[fg=${win_active_bg},bg=${status_bg}]'

# pane borders
set -g pane-border-style "fg=${border}"
set -g pane-active-border-style "fg=${accent},bold"
set -g pane-border-format "#[fg=${border}] #{pane_index}:#{pane_title} "

# messages
set -g message-style "bg=${msg_bg},fg=${msg_fg},bold"
set -g message-command-style "bg=${msg_bg},fg=${msg_fg}"
CONF
}

# generate bash prompt with theme colors
_generate_themed_prompt() {
  local theme="$1"
  local prompt_file="$BATIPANEL_HOME/config/bash-prompt.sh"

  local colors
  colors=$(_get_theme_colors "$theme") || return 1

  local prompt_user prompt_dir prompt_git prompt_err
  # shellcheck disable=SC2086
  read -r _ _ _ _ _ _ _ _ _ _ _ \
    prompt_user prompt_dir prompt_git prompt_err <<< $colors

  # map ANSI code numbers to fg transition codes
  # user bg → dir transition
  local t_user_fg
  case "$prompt_user" in
    44)  t_user_fg="34" ;;   # blue
    105) t_user_fg="105" ;;  # purple (256-color)
    67)  t_user_fg="67" ;;   # nord blue (256-color)
    172) t_user_fg="172" ;;  # gruvbox orange (256-color)
    111) t_user_fg="111" ;;  # tokyo blue (256-color)
    183) t_user_fg="183" ;;  # catppuccin mauve (256-color)
    182) t_user_fg="182" ;;  # rose-pine iris (256-color)
    103) t_user_fg="103" ;;  # kanagawa violet (256-color)
    *)   t_user_fg="34" ;;   # fallback blue
  esac

  # git bg → end transition
  local t_git_fg
  case "$prompt_git" in
    42)  t_git_fg="32" ;;    # green
    212) t_git_fg="212" ;;   # pink (256-color)
    110) t_git_fg="110" ;;   # frost (256-color)
    142) t_git_fg="142" ;;   # gruvbox green (256-color)
    141) t_git_fg="141" ;;   # purple (256-color)
    151) t_git_fg="151" ;;   # catppuccin green (256-color)
    152) t_git_fg="152" ;;   # rose-pine foam (256-color)
    107) t_git_fg="107" ;;   # kanagawa spring green (256-color)
    *)   t_git_fg="32" ;;    # fallback green
  esac

  # error bg → dir transition
  local t_err_fg
  case "$prompt_err" in
    41)  t_err_fg="31" ;;    # red
    203) t_err_fg="203" ;;   # salmon (256-color)
    131) t_err_fg="131" ;;   # nord red (256-color)
    167) t_err_fg="167" ;;   # gruvbox red (256-color)
    211) t_err_fg="211" ;;   # catppuccin red (256-color)
    168) t_err_fg="168" ;;   # rose-pine/kanagawa red (256-color)
    *)   t_err_fg="31" ;;    # fallback red
  esac

  # determine if we need 256-color or basic ANSI for bg/fg
  local bg_user bg_dir bg_git fg_git bg_err t_user_dir t_dir_git t_dir_end t_git_end t_err_dir

  # user segment bg
  if [ "$prompt_user" -le 47 ] 2>/dev/null; then
    bg_user="\\[\\e[${prompt_user}m\\]"
  else
    bg_user="\\[\\e[48;5;${prompt_user}m\\]"
  fi

  # dir segment bg (always 256-color)
  bg_dir="\\[\\e[48;5;${prompt_dir}m\\]"

  # git segment bg
  if [ "$prompt_git" -le 47 ] 2>/dev/null; then
    bg_git="\\[\\e[${prompt_git}m\\]"
  else
    bg_git="\\[\\e[48;5;${prompt_git}m\\]"
  fi

  # error segment bg
  if [ "$prompt_err" -le 47 ] 2>/dev/null; then
    bg_err="\\[\\e[${prompt_err}m\\]"
  else
    bg_err="\\[\\e[48;5;${prompt_err}m\\]"
  fi

  # git fg (text on git bg) — use black for light bg, white for dark
  case "$prompt_git" in
    42|142|151|152|107|214) fg_git="\\[\\e[30m\\]" ;;  # black text
    *)          fg_git="\\[\\e[97m\\]" ;;   # white text
  esac

  # transition: user → dir
  if [ "$t_user_fg" -le 37 ] 2>/dev/null; then
    t_user_dir="\\[\\e[${t_user_fg};48;5;${prompt_dir}m\\]"
  else
    t_user_dir="\\[\\e[38;5;${t_user_fg};48;5;${prompt_dir}m\\]"
  fi

  # transition: dir → git
  t_dir_git="\\[\\e[38;5;${prompt_dir};48;5;${prompt_git}m\\]"
  if [ "$prompt_git" -le 47 ] 2>/dev/null; then
    t_dir_git="\\[\\e[38;5;${prompt_dir};${prompt_git}m\\]"
  fi

  # transition: dir → end
  t_dir_end="\\[\\e[38;5;${prompt_dir}m\\]"

  # transition: git → end
  if [ "$t_git_fg" -le 37 ] 2>/dev/null; then
    t_git_end="\\[\\e[${t_git_fg}m\\]"
  else
    t_git_end="\\[\\e[38;5;${t_git_fg}m\\]"
  fi

  # transition: err → dir
  if [ "$t_err_fg" -le 37 ] 2>/dev/null; then
    t_err_dir="\\[\\e[${t_err_fg};48;5;${prompt_dir}m\\]"
  else
    t_err_dir="\\[\\e[38;5;${t_err_fg};48;5;${prompt_dir}m\\]"
  fi

  mkdir -p "$BATIPANEL_HOME/config"
  cat > "$prompt_file" << PROMPT_EOF
#!/usr/bin/env bash
# batipanel bash prompt - theme: ${theme} (auto-generated)

__batipanel_prompt() {
  local exit_code=\$?

  # powerline arrow symbols (U+E0B0, U+E0B1)
  local sep=\$'\\uE0B0'

  # colors (generated from theme: ${theme})
  local bg_user="${bg_user}"
  local fg_user="\\[\\e[97m\\]"
  local bg_dir="${bg_dir}"
  local fg_dir="\\[\\e[97m\\]"
  local bg_git="${bg_git}"
  local fg_git="${fg_git}"
  local bg_err="${bg_err}"
  local fg_err="\\[\\e[97m\\]"
  local reset="\\[\\e[0m\\]"

  # transition colors
  local t_user_dir="${t_user_dir}"
  local t_dir_git="${t_dir_git}"
  local t_dir_end="${t_dir_end}"
  local t_git_end="${t_git_end}"
  local t_err_dir="${t_err_dir}"

  # segment 1: username (no hostname)
  local ps=""
  if [ "\$exit_code" -ne 0 ]; then
    ps+="\${bg_err}\${fg_err} ✘ \${exit_code} "
    ps+="\${t_err_dir}\${sep}"
  fi
  ps+="\${bg_user}\${fg_user} \\\\u "

  # segment 2: working directory
  ps+="\${t_user_dir}\${sep}"
  ps+="\${bg_dir}\${fg_dir} \\\\w "

  # segment 3: git branch (if in a repo)
  local git_branch=""
  if command -v git &>/dev/null; then
    git_branch="\$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"
  fi

  if [ -n "\$git_branch" ]; then
    ps+="\${t_dir_git}\${sep}"
    local git_icon=\$'\\uE0A0'
    ps+="\${bg_git}\${fg_git} \${git_icon} \${git_branch} "
    ps+="\${reset}\${t_git_end}\${sep}\${reset} "
  else
    ps+="\${reset}\${t_dir_end}\${sep}\${reset} "
  fi

  PS1="\$ps"
}

PROMPT_COMMAND="__batipanel_prompt"
PROMPT_EOF
}

# apply theme: generate files, persist config, live reload
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
    if grep -q "BATIPANEL_THEME=" "$TMUX_CONFIG"; then
      _sed_i "s|BATIPANEL_THEME=.*|BATIPANEL_THEME=\"$theme\"|" "$TMUX_CONFIG"
    else
      echo "BATIPANEL_THEME=\"$theme\"" >> "$TMUX_CONFIG"
    fi
  else
    echo "BATIPANEL_THEME=\"$theme\"" > "$TMUX_CONFIG"
  fi

  # live reload tmux if running
  if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null 2>&1; then
    tmux source-file "$BATIPANEL_HOME/config/tmux.conf" 2>/dev/null || true
    tmux source-file "$BATIPANEL_HOME/config/theme.conf" 2>/dev/null || true
  fi

  BATIPANEL_THEME="$theme"
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
