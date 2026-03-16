#!/usr/bin/env bash
# scripts/install/tools.sh - install required (tmux, git) and optional (claude, btop, lazygit, eza, yazi) tools

# initialize architecture variables
_init_arch() {
  ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64)  ARCH_GO="x86_64" ; ARCH_YAZI="x86_64" ;;
    aarch64|arm64) ARCH_GO="arm64" ; ARCH_YAZI="aarch64" ;;
    *) ARCH_GO="$ARCH" ; ARCH_YAZI="$ARCH" ;;
  esac
  OS_LOWER="$(uname -s | tr '[:upper:]' '[:lower:]')"
}

# macOS: ensure Homebrew is in PATH if installed but not yet visible
_setup_brew_path() {
  if [ "$OS" = "Darwin" ] && ! has_cmd brew; then
    if [ -f /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
}

install_required_tools() {
  echo ""
  echo "Checking tools..."

  _setup_brew_path

  # required: tmux
  if ! command -v tmux &>/dev/null; then
    echo "Installing tmux..."
    install_packages tmux 2>/dev/null || true
  fi

  # fallback: install via micromamba (no admin, no package manager needed)
  if ! command -v tmux &>/dev/null; then
    install_via_mamba tmux || true
  fi

  if ! command -v tmux &>/dev/null; then
    echo ""
    echo "tmux is required but could not be installed."
    if [ "$OS" = "Darwin" ]; then
      echo "Install via Homebrew:  brew install tmux"
    else
      echo "Install via package manager:  sudo apt install tmux  (or equivalent)"
    fi
    exit 1
  fi

  # smoke test: verify tmux can actually start a server
  _tmux_smoke_ok=0
  if tmux -f /dev/null new-session -d -s _bp_smoke -x 10 -y 5 2>/dev/null; then
    tmux kill-session -t _bp_smoke 2>/dev/null || true
    _tmux_smoke_ok=1
  fi

  # if smoke test failed, clean stale socket and retry (common on macOS)
  if [ "$_tmux_smoke_ok" = "0" ]; then
    # warn if there are active tmux sessions before killing server
    if tmux list-sessions 2>/dev/null | grep -q .; then
      echo "  WARNING: killing tmux server with active sessions to clear stale state"
    fi
    tmux kill-server 2>/dev/null || true
    rm -rf "/tmp/tmux-$(id -u)/" "/private/tmp/tmux-$(id -u)/" 2>/dev/null || true
    sleep 0.3
    if tmux -f /dev/null new-session -d -s _bp_smoke -x 10 -y 5 2>/dev/null; then
      tmux kill-session -t _bp_smoke 2>/dev/null || true
      _tmux_smoke_ok=1
      echo "  Cleared stale tmux socket — tmux is working now."
    fi
  fi

  if [ "$_tmux_smoke_ok" = "0" ]; then
    echo ""
    echo "WARNING: tmux is installed but fails to start (server exited unexpectedly)."
    # if mamba tmux exists, it may be the broken one — remove wrapper so brew takes priority
    if [ -f "$BATIPANEL_HOME/bin/tmux" ] && [ -d "$BATIPANEL_HOME/.mamba" ]; then
      echo "  Removing unstable conda-forge tmux..."
      rm -f "$BATIPANEL_HOME/bin/tmux"
    fi
    if [ "$OS" = "Darwin" ]; then
      echo "  Try: brew reinstall tmux"
    else
      echo "  Try: sudo apt install --reinstall tmux"
    fi
    # re-check after removing mamba wrapper
    if command -v tmux &>/dev/null && tmux -f /dev/null new-session -d -s _bp_smoke2 -x 10 -y 5 2>/dev/null; then
      tmux kill-session -t _bp_smoke2 2>/dev/null || true
      echo "  Found working system tmux: $(tmux -V)"
    else
      echo ""
      echo "tmux is required. Install it and re-run this installer."
      exit 1
    fi
  fi

  # version check: tmux 2.6+ required for -p (percentage splits)
  _tmux_ver=$(tmux -V 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
  _tmux_major="${_tmux_ver%%.*}"
  _tmux_minor="${_tmux_ver#*.}"
  _tmux_minor="${_tmux_minor%%[a-z]*}"  # strip suffix like "3.6a" → "6"
  if [ -n "$_tmux_ver" ] && (( _tmux_major < 2 || (_tmux_major == 2 && _tmux_minor < 6) )); then
    echo ""
    echo "  tmux $_tmux_ver is too old (need 2.6+). Installing newer version..."
    _tmux_upgraded=false

    # try 1: micromamba (provides tmux 3.x from conda-forge)
    if install_via_mamba tmux 2>/dev/null; then
      _tmux_upgraded=true
    fi

    # try 2: compile from source (works on Amazon Linux, CentOS, etc.)
    if [ "$_tmux_upgraded" = false ] && [ "$OS" != "Darwin" ]; then
      echo "  Trying to build tmux from source..."
      _tmux_build_ver="3.4"
      _tmux_build_dir=$(mktemp -d)
      # install build dependencies
      if command -v yum &>/dev/null; then
        sudo yum install -y libevent-devel ncurses-devel gcc make bison byacc 2>/dev/null || true
      elif command -v apt-get &>/dev/null; then
        sudo apt-get install -y libevent-dev libncurses-dev gcc make bison 2>/dev/null || true
      elif command -v dnf &>/dev/null; then
        sudo dnf install -y libevent-devel ncurses-devel gcc make bison 2>/dev/null || true
      fi
      if curl -fsSL "https://github.com/tmux/tmux/releases/download/${_tmux_build_ver}/tmux-${_tmux_build_ver}.tar.gz" \
          | tar xz -C "$_tmux_build_dir" 2>/dev/null; then
        if (cd "$_tmux_build_dir/tmux-${_tmux_build_ver}" && ./configure --prefix="$HOME/.local" 2>/dev/null && make -j"$(nproc 2>/dev/null || echo 2)" 2>/dev/null && make install 2>/dev/null); then
          export PATH="$HOME/.local/bin:$PATH"
          _tmux_upgraded=true
          echo "  Built tmux ${_tmux_build_ver} → ~/.local/bin/tmux"
        fi
      fi
      rm -rf "$_tmux_build_dir"
    fi

    if [ "$_tmux_upgraded" = true ]; then
      echo "  Upgraded tmux to $(tmux -V 2>/dev/null || echo 'unknown')"
    else
      echo ""
      echo "WARNING: tmux $_tmux_ver is too old and auto-upgrade failed."
      echo "  batipanel requires tmux 2.6+."
      echo ""
      echo "  Install manually:"
      if [ "$OS" = "Darwin" ]; then
        echo "    brew install tmux"
      else
        echo "    sudo snap install tmux --classic"
        echo "    # or: https://github.com/tmux/tmux/wiki/Installing"
      fi
      exit 1
    fi
  fi

  # ensure git >= 2.32 (required by lazygit)
  if has_cmd git; then
    GIT_VER=$(git --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
    GIT_MAJOR="${GIT_VER%%.*}"
    GIT_MINOR="${GIT_VER#*.}"
    if (( GIT_MAJOR < 2 || (GIT_MAJOR == 2 && GIT_MINOR < 32) )); then
      echo ""
      echo "Git $GIT_VER is too old (lazygit needs 2.32+). Upgrading..."
      if command -v apt-get &>/dev/null; then
        # add-apt-repository needs software-properties-common
        if ! has_cmd add-apt-repository; then
          sudo apt-get install -y -qq software-properties-common 2>/dev/null || true
        fi
        sudo add-apt-repository -y ppa:git-core/ppa 2>/dev/null || true
        sudo apt-get update -qq 2>/dev/null
        sudo apt-get install -y -qq git 2>/dev/null || true
        NEW_GIT_VER=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        echo "  Git upgraded to $NEW_GIT_VER"
      elif command -v dnf &>/dev/null; then
        sudo dnf install -y git 2>/dev/null || true
      else
        echo "  Please upgrade git manually to 2.32+"
      fi
    fi
  fi
}

install_optional_tools() {
  echo ""
  echo "Installing optional tools..."

  _init_arch

  # claude code (official standalone installer — no Node.js required)
  if ! has_cmd claude; then
    echo "  Installing Claude Code..."
    if curl -fsSL https://claude.ai/install.sh | bash 2>/dev/null; then
      # installer adds to PATH but current shell may not have it yet
      export PATH="$HOME/.claude/bin:$PATH"
      if has_cmd claude; then
        echo "  Claude Code installed"
      else
        echo "  Claude Code installer ran but 'claude' not found in PATH"
      fi
    else
      echo "  Claude Code auto-install failed"
      echo "  Install manually: curl -fsSL https://claude.ai/install.sh | bash"
    fi
  fi

  # btop
  if ! has_cmd btop; then
    install_packages btop 2>/dev/null || true
  fi
  # btop GitHub releases only provide Linux binaries
  if ! has_cmd btop && [ "$OS_LOWER" = "linux" ]; then
    tag=$(latest_github_tag "aristocratos/btop")
    if [ -n "$tag" ]; then
      _btop_arch="$ARCH"
      case "$ARCH" in
        aarch64|arm64) _btop_arch="aarch64" ;;
      esac
      install_from_github btop \
        "https://github.com/aristocratos/btop/releases/download/${tag}/btop-${_btop_arch}-unknown-linux-musl.tbz" 2>/dev/null || true
    fi
  fi

  # lazygit — verify it actually works (old binary may fail with git version error)
  LAZYGIT_OK=0
  if has_cmd lazygit; then
    if lazygit --version &>/dev/null; then
      LAZYGIT_OK=1
    else
      echo "  Existing lazygit is broken, reinstalling..."
      sudo rm -f /usr/local/bin/lazygit 2>/dev/null; rm -f "$HOME/.local/bin/lazygit" 2>/dev/null
    fi
  fi
  if [ "$LAZYGIT_OK" = "0" ]; then
    install_packages lazygit 2>/dev/null || true
  fi
  if [ "$LAZYGIT_OK" = "0" ] && ! has_cmd lazygit; then
    tag=$(latest_github_tag "jesseduffield/lazygit")
    ver="${tag#v}"
    if [ -n "$ver" ]; then
      install_from_github lazygit \
        "https://github.com/jesseduffield/lazygit/releases/download/${tag}/lazygit_${ver}_${OS_LOWER}_${ARCH_GO}.tar.gz"
    fi
  fi

  # eza
  if ! has_cmd eza; then
    install_packages eza 2>/dev/null || true
  fi
  if ! has_cmd eza && [ "$OS_LOWER" = "linux" ]; then
    tag=$(latest_github_tag "eza-community/eza")
    if [ -n "$tag" ]; then
      # try gnu first, fall back to musl (statically linked)
      install_from_github eza \
        "https://github.com/eza-community/eza/releases/download/${tag}/eza_${ARCH_YAZI}-unknown-linux-gnu.tar.gz" \
        || install_from_github eza \
          "https://github.com/eza-community/eza/releases/download/${tag}/eza_${ARCH_YAZI}-unknown-linux-musl.tar.gz"
    fi
  fi

  # yazi — verify it actually works (glibc mismatch may cause failure)
  YAZI_OK=0
  if has_cmd yazi; then
    if yazi --version &>/dev/null; then
      YAZI_OK=1
    else
      echo "  Existing yazi is broken (likely glibc mismatch), reinstalling..."
      sudo rm -f /usr/local/bin/yazi 2>/dev/null; rm -f "$HOME/.local/bin/yazi" 2>/dev/null
    fi
  fi
  if [ "$YAZI_OK" = "0" ]; then
    install_packages yazi 2>/dev/null || true
  fi
  if [ "$YAZI_OK" = "0" ] && ! has_cmd yazi; then
    tag=$(latest_github_tag "sxyazi/yazi")
    if [ -n "$tag" ]; then
      if [ "$OS_LOWER" = "darwin" ]; then
        install_from_github yazi \
          "https://github.com/sxyazi/yazi/releases/download/${tag}/yazi-${ARCH_YAZI}-apple-darwin.zip"
      else
        # use musl build (statically linked, no glibc version dependency)
        install_from_github yazi \
          "https://github.com/sxyazi/yazi/releases/download/${tag}/yazi-${ARCH_YAZI}-unknown-linux-musl.zip"
      fi
    fi
  fi
}
