#!/usr/bin/env bash
# batipanel themes-bash - generate bash prompt with theme colors

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

# load theme colors for OSC
_bp_env="\$HOME/.batipanel/config/theme-env.sh"
[ -f "\$_bp_env" ] && source "\$_bp_env"

# set terminal colors via OSC sequences (skip Apple_Terminal — no OSC 10/11/12 support)
if [[ "\$TERM" != "dumb" ]] && [[ "\${TERM_PROGRAM:-}" != "Apple_Terminal" ]] && [[ -n "\${BP_BG:-}" ]]; then
  printf '\e]11;%s\a' "\$BP_BG"
  printf '\e]10;%s\a' "\$BP_FG"
  printf '\e]12;%s\a' "\$BP_CURSOR"
fi

__batipanel_prompt() {
  local exit_code=\$?

  # detect powerline glyph support at runtime
  local sep git_icon=""
  local _use_pl=0
  case "\${TERM_PROGRAM:-}" in
    iTerm.app|WezTerm|kitty|Hyper|Alacritty|vscode) _use_pl=1 ;;
  esac
  [[ -n "\${TMUX:-}" ]] && _use_pl=1
  [[ "\${BATIPANEL_ICONS:-0}" == "1" ]] && _use_pl=1
  if (( _use_pl )); then
    sep=\$'\\uE0B0'
    git_icon=\$'\\uE0A0'
  else
    sep='>'
  fi

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
    if [ -n "\$git_icon" ]; then
      ps+="\${bg_git}\${fg_git} \${git_icon} \${git_branch} "
    else
      ps+="\${bg_git}\${fg_git} \${git_branch} "
    fi
    ps+="\${reset}\${t_git_end}\${sep}\${reset} "
  else
    ps+="\${reset}\${t_dir_end}\${sep}\${reset} "
  fi

  PS1="\$ps"
}

PROMPT_COMMAND="__batipanel_prompt"
PROMPT_EOF
}
