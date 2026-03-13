#!/usr/bin/env bats
# tests for themes modules

load test_helper

setup() {
  setup_batipanel_env
  load_batipanel_modules
  source "$BATIPANEL_HOME/lib/themes-data.sh"
  source "$BATIPANEL_HOME/lib/themes-tmux.sh"
  source "$BATIPANEL_HOME/lib/themes-bash.sh"
  source "$BATIPANEL_HOME/lib/themes.sh"
}

teardown() {
  teardown_batipanel_env
}

# === theme data ===

@test "_get_theme_colors returns colors for all built-in themes" {
  for theme in default dracula nord gruvbox tokyo-night catppuccin rose-pine kanagawa; do
    run _get_theme_colors "$theme"
    [ "$status" -eq 0 ]
    # should return 15 space-separated values
    local count
    count=$(echo "$output" | wc -w)
    [ "$count" -eq 15 ]
  done
}

@test "_get_theme_colors fails for unknown theme" {
  run _get_theme_colors "nonexistent"
  [ "$status" -eq 1 ]
}

@test "_get_theme_desc returns description for all themes" {
  for theme in default dracula nord gruvbox tokyo-night catppuccin rose-pine kanagawa; do
    run _get_theme_desc "$theme"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
  done
}

# === tmux theme generation ===

@test "_generate_theme_conf creates theme.conf" {
  run _generate_theme_conf "default"
  [ "$status" -eq 0 ]
  [ -f "$BATIPANEL_HOME/config/theme.conf" ]
  grep -q "status-style" "$BATIPANEL_HOME/config/theme.conf"
  grep -q "pane-border-style" "$BATIPANEL_HOME/config/theme.conf"
}

@test "_generate_theme_conf fails for unknown theme" {
  run _generate_theme_conf "nonexistent"
  [ "$status" -eq 1 ]
}

# === bash prompt generation ===

@test "_generate_themed_prompt creates bash-prompt.sh" {
  run _generate_themed_prompt "dracula"
  [ "$status" -eq 0 ]
  [ -f "$BATIPANEL_HOME/config/bash-prompt.sh" ]
  grep -q "__batipanel_prompt" "$BATIPANEL_HOME/config/bash-prompt.sh"
  grep -q "PROMPT_COMMAND" "$BATIPANEL_HOME/config/bash-prompt.sh"
}

@test "_generate_themed_prompt output is valid bash" {
  _generate_themed_prompt "default"
  bash -n "$BATIPANEL_HOME/config/bash-prompt.sh"
}

# === BATIPANEL_THEMES list ===

@test "BATIPANEL_THEMES contains 8 themes" {
  local count
  count=$(echo "$BATIPANEL_THEMES" | wc -w)
  [ "$count" -eq 8 ]
}
