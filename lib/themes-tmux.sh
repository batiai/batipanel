#!/usr/bin/env bash
# batipanel themes-tmux - generate tmux theme overlay file

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
