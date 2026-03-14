#!/usr/bin/env bash
# batipanel shell-setup - prompt theme, terminal colors

BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"

if ! declare -f has_cmd &>/dev/null; then
  has_cmd() { command -v "$1" &>/dev/null; }
fi
if ! declare -f _sed_i &>/dev/null; then
  _sed_i() {
    if [ "$(uname -s)" = "Darwin" ]; then
      sed -i '' "$@"
    else
      sed -i "$@"
    fi
  }
fi

# === 1. Generate theme env file ===
# This small file is sourced by both zsh and bash prompts
generate_theme_env() {
  local theme="${1:-default}"
  local env_file="$BATIPANEL_HOME/config/theme-env.sh"
  mkdir -p "$BATIPANEL_HOME/config"

  # get terminal colors (needs themes-data.sh to be sourced)
  local term_colors
  if declare -f _get_theme_terminal_colors &>/dev/null; then
    term_colors=$(_get_theme_terminal_colors "$theme")
  else
    term_colors="#1e1e2e #cdd6f4 #f5e0dc blue cyan green magenta"
  fi

  local bg fg cursor c_user c_dir c_git c_prompt
  read -r bg fg cursor c_user c_dir c_git c_prompt <<< "$term_colors"

  cat > "$env_file" << EOF
# batipanel theme colors (auto-generated, do not edit)
BP_THEME="$theme"
BP_BG="$bg"
BP_FG="$fg"
BP_CURSOR="$cursor"
BP_C_USER="$c_user"
BP_C_DIR="$c_dir"
BP_C_GIT="$c_git"
BP_C_PROMPT="$c_prompt"
EOF
}

# === 2. Generate zsh prompt ===
_generate_zsh_prompt() {
  local prompt_file="$BATIPANEL_HOME/config/zsh-prompt.zsh"
  mkdir -p "$BATIPANEL_HOME/config"

  # ensure theme env exists
  local theme="${BATIPANEL_THEME:-default}"
  generate_theme_env "$theme"

  cat > "$prompt_file" << 'ZSH_PROMPT_EOF'
# batipanel zsh prompt
_bp_env="$HOME/.batipanel/config/theme-env.sh"
[[ -f "$_bp_env" ]] && source "$_bp_env"

autoload -U colors && colors
autoload -Uz vcs_info
setopt PROMPT_SUBST

precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' %F{green}(%b)%f'
zstyle ':vcs_info:*' enable git

PROMPT='%F{blue}%n%f %F{cyan}%~%f${vcs_info_msg_0_} %F{magenta}>%f '
RPROMPT='%(?..%F{red}[%?]%f)'
ZSH_PROMPT_EOF
}

# === 3. Setup zsh prompt ===
setup_zsh_theme() {
  local shell_rc="$1"

  echo "  Configuring zsh prompt..."
  _generate_zsh_prompt

  local prompt_file="$BATIPANEL_HOME/config/zsh-prompt.zsh"
  local source_line="[[ -f \"$prompt_file\" ]] && source \"$prompt_file\""

  if [ -f "$shell_rc" ]; then
    if ! grep -qF "zsh-prompt.zsh" "$shell_rc" 2>/dev/null; then
      {
        echo ""
        echo "# batipanel prompt theme"
        echo "$source_line"
      } >> "$shell_rc"
    fi
  else
    echo "$source_line" > "$shell_rc"
  fi

  echo "    Set prompt theme"
}

# === 4. Bash prompt ===
_setup_default_bash_prompt() {
  local prompt_file="$BATIPANEL_HOME/config/bash-prompt.sh"
  mkdir -p "$BATIPANEL_HOME/config"

  local theme="${BATIPANEL_THEME:-default}"
  generate_theme_env "$theme"

  cat > "$prompt_file" << 'BASH_PROMPT_EOF'
#!/usr/bin/env bash
# batipanel bash prompt

# load theme colors
_bp_env="$HOME/.batipanel/config/theme-env.sh"
[ -f "$_bp_env" ] && source "$_bp_env"

# set terminal colors via OSC
if [[ "$TERM" != "dumb" ]]; then
  printf "\e]11;${BP_BG:-#1e1e2e}\a"
  printf "\e]10;${BP_FG:-#cdd6f4}\a"
  printf "\e]12;${BP_CURSOR:-#f5e0dc}\a"
fi

__batipanel_prompt() {
  local exit_code=$?
  local reset="\[\e[0m\]"
  local ps=""
  if [ "$exit_code" -ne 0 ]; then
    ps+="\[\e[31m\][${exit_code}] "
  fi
  ps+="\[\e[34m\]\\u${reset} \[\e[36m\]\\w${reset}"
  local git_branch=""
  if command -v git &>/dev/null; then
    git_branch="$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"
  fi
  if [ -n "$git_branch" ]; then
    ps+=" \[\e[32m\](${git_branch})${reset}"
  fi
  ps+=" \[\e[35m\]>${reset} "
  PS1="$ps"
}
PROMPT_COMMAND="__batipanel_prompt"
BASH_PROMPT_EOF
}

setup_bash_prompt() {
  local shell_rc="$1"
  echo "  Configuring bash prompt..."

  local current_theme="${BATIPANEL_THEME:-default}"
  if declare -f _generate_themed_prompt &>/dev/null; then
    _generate_themed_prompt "$current_theme"
  else
    _setup_default_bash_prompt
  fi

  local prompt_file="$BATIPANEL_HOME/config/bash-prompt.sh"
  local source_line="source \"$prompt_file\""
  _add_line_if_missing "$shell_rc" "bash-prompt.sh" "$source_line"

  echo "    Set prompt theme"
}

# === Helper ===
_add_line_if_missing() {
  local rc_file="$1"
  local search="$2"
  local line="$3"

  if [ ! -f "$rc_file" ]; then
    echo "$line" >> "$rc_file"
    return
  fi

  if ! grep -qF "$search" "$rc_file" 2>/dev/null; then
    {
      echo ""
      echo "# batipanel shell theme"
      echo "$line"
    } >> "$rc_file"
  fi
}

# === Main entry point ===
setup_shell_environment() {
  local user_shell="$1"
  local shell_rc="$2"

  echo ""
  echo "Setting up shell environment..."

  case "$user_shell" in
    zsh)  setup_zsh_theme "$shell_rc" ;;
    bash) setup_bash_prompt "$shell_rc" ;;
    *)    echo "  Unsupported shell ($user_shell), skipping prompt setup" ;;
  esac

  echo "  Shell environment setup complete"
}
