#!/usr/bin/env bash
# batipanel shell-setup - powerline fonts, prompt theme, hostname hiding

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
  if fc-list 2>/dev/null | grep -qi "powerline\|nerd"; then
    echo "    Powerline-compatible fonts already installed"
    return 0
  fi

  case "$OS" in
    Darwin)
      if has_cmd brew; then
        # install Nerd Font (includes powerline glyphs)
        brew tap homebrew/cask-fonts 2>/dev/null || true
        if brew install --cask font-meslo-lg-nerd-font 2>/dev/null; then
          echo "    Installed MesloLGS Nerd Font (macOS)"
        else
          echo "    Font install via brew failed, trying powerline-fonts..."
          _install_powerline_fonts_git
        fi
      else
        _install_powerline_fonts_git
      fi
      ;;
    Linux)
      if has_cmd apt-get; then
        if sudo apt-get install -y -qq fonts-powerline 2>/dev/null; then
          echo "    Installed fonts-powerline (apt)"
        else
          _install_powerline_fonts_git
        fi
      elif has_cmd dnf; then
        if sudo dnf install -y powerline-fonts 2>/dev/null; then
          echo "    Installed powerline-fonts (dnf)"
        else
          _install_powerline_fonts_git
        fi
      elif has_cmd pacman; then
        if sudo pacman -S --noconfirm powerline-fonts 2>/dev/null; then
          echo "    Installed powerline-fonts (pacman)"
        else
          _install_powerline_fonts_git
        fi
      else
        _install_powerline_fonts_git
      fi
      ;;
    *)
      _install_powerline_fonts_git
      ;;
  esac
}

# fallback: clone and install powerline fonts from GitHub
_install_powerline_fonts_git() {
  if ! has_cmd git; then
    echo "    git not found, skipping font install"
    return 1
  fi

  local tmpdir
  tmpdir=$(mktemp -d)
  if git clone --depth=1 https://github.com/powerline/fonts.git "$tmpdir/fonts" 2>/dev/null; then
    bash "$tmpdir/fonts/install.sh" 2>/dev/null || true
    echo "    Installed powerline fonts from GitHub"
  else
    echo "    Failed to clone powerline fonts"
  fi
  rm -rf "$tmpdir"
}

# === 2. Setup zsh with Oh My Zsh + agnoster ===
setup_zsh_theme() {
  local shell_rc="$1"

  echo "  Configuring zsh theme..."

  # install Oh My Zsh if not present
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "    Installing Oh My Zsh..."
    if has_cmd curl; then
      RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>/dev/null || true
    elif has_cmd wget; then
      RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>/dev/null || true
    else
      echo "    curl/wget not found, skipping Oh My Zsh"
      return 1
    fi
  fi

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "    Oh My Zsh installation failed"
    return 1
  fi

  # set agnoster theme
  if [ -f "$shell_rc" ]; then
    if grep -q 'ZSH_THEME=' "$shell_rc" 2>/dev/null; then
      _sed_i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$shell_rc"
    else
      echo 'ZSH_THEME="agnoster"' >> "$shell_rc"
    fi
  fi

  # hide hostname: set DEFAULT_USER to current user
  _add_line_if_missing "$shell_rc" "DEFAULT_USER" \
    "DEFAULT_USER=\"\$(whoami)\""

  echo "    Set agnoster theme with hostname hidden"
}

# fallback prompt generator (when themes.sh is not loaded)
_setup_default_bash_prompt() {
  local prompt_file="$BATIPANEL_HOME/config/bash-prompt.sh"
  mkdir -p "$BATIPANEL_HOME/config"
  cat > "$prompt_file" << 'FALLBACK_EOF'
#!/usr/bin/env bash
# batipanel bash prompt - default theme (fallback)
__batipanel_prompt() {
  local exit_code=$?
  local sep=$'\uE0B0'
  local bg_user="\[\e[44m\]"
  local fg_user="\[\e[97m\]"
  local bg_dir="\[\e[48;5;240m\]"
  local fg_dir="\[\e[97m\]"
  local bg_git="\[\e[42m\]"
  local fg_git="\[\e[30m\]"
  local bg_err="\[\e[41m\]"
  local fg_err="\[\e[97m\]"
  local reset="\[\e[0m\]"
  local t_user_dir="\[\e[34;48;5;240m\]"
  local t_dir_git="\[\e[38;5;240;42m\]"
  local t_dir_end="\[\e[38;5;240m\]"
  local t_git_end="\[\e[32m\]"
  local t_err_dir="\[\e[31;48;5;240m\]"
  local ps=""
  if [ "$exit_code" -ne 0 ]; then
    ps+="${bg_err}${fg_err} ✘ ${exit_code} "
    ps+="${t_err_dir}${sep}"
  fi
  ps+="${bg_user}${fg_user} \\u "
  ps+="${t_user_dir}${sep}"
  ps+="${bg_dir}${fg_dir} \\w "
  local git_branch=""
  if command -v git &>/dev/null; then
    git_branch="$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"
  fi
  if [ -n "$git_branch" ]; then
    ps+="${t_dir_git}${sep}"
    local git_icon=$'\uE0A0'
    ps+="${bg_git}${fg_git} ${git_icon} ${git_branch} "
    ps+="${reset}${t_git_end}${sep}${reset} "
  else
    ps+="${reset}${t_dir_end}${sep}${reset} "
  fi
  PS1="$ps"
}
PROMPT_COMMAND="__batipanel_prompt"
FALLBACK_EOF
}

# === 3. Setup bash powerline prompt ===
setup_bash_prompt() {
  local shell_rc="$1"

  echo "  Configuring bash prompt..."

  # generate prompt with current theme (uses _generate_themed_prompt from themes.sh)
  local current_theme="${BATIPANEL_THEME:-default}"
  if declare -f _generate_themed_prompt &>/dev/null; then
    _generate_themed_prompt "$current_theme"
  else
    # fallback: generate default prompt directly (standalone install without themes.sh)
    _setup_default_bash_prompt
  fi

  # source prompt from shell RC
  local prompt_file="$BATIPANEL_HOME/config/bash-prompt.sh"
  local source_line="source \"$prompt_file\""
  _add_line_if_missing "$shell_rc" "bash-prompt.sh" "$source_line"

  echo "    Set powerline-style prompt (hostname hidden)"
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
