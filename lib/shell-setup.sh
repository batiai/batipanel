#!/usr/bin/env bash
# batipanel shell-setup - powerline fonts, prompt theme, hostname hiding

BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"

has_cmd() { command -v "$1" &>/dev/null; }

# portable sed -i (macOS vs GNU) — may already be defined by caller
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

# === 3. Setup bash powerline prompt ===
setup_bash_prompt() {
  local shell_rc="$1"

  echo "  Configuring bash prompt..."

  # create powerline-style prompt script
  local prompt_file="$BATIPANEL_HOME/config/bash-prompt.sh"
  cat > "$prompt_file" << 'PROMPT_EOF'
#!/usr/bin/env bash
# batipanel bash prompt - powerline style (no hostname)

__batipanel_prompt() {
  local exit_code=$?

  # powerline symbols (fallback to ASCII if terminal doesn't support)
  local sep=""
  local sep_thin=""

  # colors
  local bg_user="\[\e[44m\]"      # blue bg
  local fg_user="\[\e[97m\]"      # white fg
  local bg_dir="\[\e[48;5;240m\]" # dark gray bg
  local fg_dir="\[\e[97m\]"       # white fg
  local bg_git="\[\e[42m\]"       # green bg
  local fg_git="\[\e[30m\]"       # black fg
  local bg_err="\[\e[41m\]"       # red bg
  local fg_err="\[\e[97m\]"       # white fg
  local reset="\[\e[0m\]"

  # transition colors
  local t_user_dir="\[\e[34;48;5;240m\]"   # blue fg on gray bg
  local t_dir_git="\[\e[38;5;240;42m\]"    # gray fg on green bg
  local t_dir_end="\[\e[38;5;240m\]"       # gray fg on default bg
  local t_git_end="\[\e[32m\]"             # green fg on default bg
  local t_err_dir="\[\e[31;48;5;240m\]"    # red fg on gray bg

  # segment 1: username (no hostname)
  local ps=""
  if [ "$exit_code" -ne 0 ]; then
    ps+="${bg_err}${fg_err} ✘ ${exit_code} "
    ps+="${t_err_dir}${sep}"
  fi
  ps+="${bg_user}${fg_user} \\u "

  # segment 2: working directory
  ps+="${t_user_dir}${sep}"
  ps+="${bg_dir}${fg_dir} \\w "

  # segment 3: git branch (if in a repo)
  local git_branch=""
  if command -v git &>/dev/null; then
    git_branch="$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"
  fi

  if [ -n "$git_branch" ]; then
    ps+="${t_dir_git}${sep}"
    ps+="${bg_git}${fg_git}  ${git_branch} "
    ps+="${reset}${t_git_end}${sep}${reset} "
  else
    ps+="${reset}${t_dir_end}${sep}${reset} "
  fi

  PS1="$ps"
}

PROMPT_COMMAND="__batipanel_prompt"
PROMPT_EOF

  # source prompt from shell RC
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
    echo "" >> "$rc_file"
    echo "# batipanel shell theme" >> "$rc_file"
    echo "$line" >> "$rc_file"
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
