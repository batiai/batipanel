#!/usr/bin/env bash
# batipanel shell-setup - prompt theme, terminal colors, powerline fonts

BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"

# has_cmd and _sed_i are expected from the caller (install.sh or core.sh)
# define fallbacks only if not already available
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

# === 1. Install powerline fonts ===
install_powerline_fonts() {
  echo "  Setting up Powerline fonts..."

  local OS
  OS="$(uname -s)"

  # check if already installed
  if [ "$OS" = "Darwin" ] && [ -d "$HOME/Library/Fonts" ]; then
    if ls "$HOME/Library/Fonts/"*owerline* &>/dev/null 2>&1 \
      || ls "$HOME/Library/Fonts/"*erd* &>/dev/null 2>&1; then
      echo "    Powerline-compatible fonts already installed"
      return 0
    fi
  elif fc-list 2>/dev/null | grep -qi "powerline\|nerd"; then
    echo "    Powerline-compatible fonts already installed"
    return 0
  fi

  # clone and install powerline fonts from GitHub (works on all platforms)
  if ! has_cmd git; then
    echo "    git not found, skipping font install"
    return 1
  fi

  local tmpdir
  tmpdir=$(mktemp -d)
  if git clone --depth=1 https://github.com/powerline/fonts.git "$tmpdir/fonts" 2>/dev/null; then
    bash "$tmpdir/fonts/install.sh" 2>/dev/null || true
    echo "    Installed powerline fonts"
  else
    echo "    Failed to download powerline fonts (optional)"
  fi
  rm -rf "$tmpdir"
}

# === 2. Generate zsh prompt config file ===
# Writes a standalone zsh prompt config that works WITHOUT Oh My Zsh
_generate_zsh_prompt() {
  local prompt_file="$BATIPANEL_HOME/config/zsh-prompt.zsh"
  mkdir -p "$BATIPANEL_HOME/config"

  cat > "$prompt_file" << 'ZSH_PROMPT_EOF'
# batipanel zsh prompt (no Oh My Zsh needed)
# This file is sourced from .zshrc

autoload -U colors && colors
autoload -Uz vcs_info
setopt PROMPT_SUBST

# detect powerline font support
_bp_sep='▸'
_bp_git='⎇'
if [[ "$(uname -s)" == "Darwin" ]]; then
  if ls ~/Library/Fonts/*owerline* &>/dev/null 2>&1 \
    || ls ~/Library/Fonts/*erd* &>/dev/null 2>&1 \
    || ls /Library/Fonts/*erd* &>/dev/null 2>&1; then
    _bp_sep=$'\uE0B0'
    _bp_git=$'\uE0A0'
  fi
else
  if fc-list 2>/dev/null | grep -qi "powerline\|nerd"; then
    _bp_sep=$'\uE0B0'
    _bp_git=$'\uE0A0'
  fi
fi

precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats " %F{black}%K{green} ${_bp_git} %b %k%F{green}${_bp_sep}%f"
zstyle ':vcs_info:*' enable git

# dark terminal colors via OSC (works immediately, no Terminal.app config needed)
if [[ "$TERM" != "dumb" ]]; then
  printf '\e]11;#1e1e2e\a'  # background: catppuccin base
  printf '\e]10;#cdd6f4\a'  # foreground: catppuccin text
  printf '\e]12;#f5e0dc\a'  # cursor: catppuccin rosewater
fi

# prompt
PROMPT="%K{blue}%F{white} %n %f%k%F{blue}%K{240}${_bp_sep}%f%F{white} %~ %f%k%F{240}\${vcs_info_msg_0_:-%F{240}${_bp_sep}}%f "
RPROMPT='%(?..%F{red}✘ %?%f)'
ZSH_PROMPT_EOF
}

# === 3. Setup zsh prompt (direct, no Oh My Zsh) ===
setup_zsh_theme() {
  local shell_rc="$1"

  echo "  Configuring zsh prompt..."

  # generate the prompt file
  _generate_zsh_prompt

  # add source line to .zshrc if not present
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

  echo "    Set powerline-style prompt"
}

# === 4. Bash prompt (fallback) ===
_setup_default_bash_prompt() {
  local prompt_file="$BATIPANEL_HOME/config/bash-prompt.sh"
  mkdir -p "$BATIPANEL_HOME/config"
  cat > "$prompt_file" << 'FALLBACK_EOF'
#!/usr/bin/env bash
# batipanel bash prompt - powerline style

# dark terminal colors via OSC
if [[ "$TERM" != "dumb" ]]; then
  printf '\e]11;#1e1e2e\a'
  printf '\e]10;#cdd6f4\a'
  printf '\e]12;#f5e0dc\a'
fi

# detect powerline font
_bp_sep='▸'
_bp_git='⎇'
if [ "$(uname -s)" = "Darwin" ]; then
  if ls ~/Library/Fonts/*owerline* &>/dev/null 2>&1 \
    || ls ~/Library/Fonts/*erd* &>/dev/null 2>&1; then
    _bp_sep=$'\uE0B0'
    _bp_git=$'\uE0A0'
  fi
elif fc-list 2>/dev/null | grep -qi "powerline\|nerd"; then
  _bp_sep=$'\uE0B0'
  _bp_git=$'\uE0A0'
fi

__batipanel_prompt() {
  local exit_code=$?
  local bg_user="\[\e[44m\]"
  local fg_user="\[\e[97m\]"
  local bg_dir="\[\e[48;5;240m\]"
  local fg_dir="\[\e[97m\]"
  local bg_git="\[\e[42m\]"
  local fg_git="\[\e[30m\]"
  local reset="\[\e[0m\]"
  local t_user="\[\e[34;48;5;240m\]"
  local t_dir="\[\e[38;5;240;42m\]"
  local t_end="\[\e[38;5;240m\]"
  local t_git="\[\e[32m\]"
  local ps=""
  if [ "$exit_code" -ne 0 ]; then
    ps+="\[\e[41m\]\[\e[97m\] ✘ ${exit_code} \[\e[31;48;5;240m\]${_bp_sep}"
  fi
  ps+="${bg_user}${fg_user} \\u ${t_user}${_bp_sep}"
  ps+="${bg_dir}${fg_dir} \\w "
  local git_branch=""
  if command -v git &>/dev/null; then
    git_branch="$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"
  fi
  if [ -n "$git_branch" ]; then
    ps+="${t_dir}${_bp_sep}${bg_git}${fg_git} ${_bp_git} ${git_branch} ${reset}${t_git}${_bp_sep}${reset} "
  else
    ps+="${reset}${t_end}${_bp_sep}${reset} "
  fi
  PS1="$ps"
}
PROMPT_COMMAND="__batipanel_prompt"
FALLBACK_EOF
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

  echo "    Set powerline-style prompt"
}

# === Helper: add line to RC if not already present ===
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

  # install powerline fonts
  install_powerline_fonts

  # configure prompt based on shell
  case "$user_shell" in
    zsh)
      setup_zsh_theme "$shell_rc"
      ;;
    bash)
      setup_bash_prompt "$shell_rc"
      ;;
    *)
      echo "  Unsupported shell ($user_shell), skipping prompt setup"
      ;;
  esac

  echo "  Shell environment setup complete"
}
