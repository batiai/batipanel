#!/usr/bin/env bash
# install.sh - batipanel installer (macOS / Linux)

set -euo pipefail

BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"

echo "batipanel - Setting up AI development workspace..."

# detect OS
OS="$(uname -s)"

# portable sed -i (macOS vs GNU)
sed_i() {
  if [ "$OS" = "Darwin" ]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

has_cmd() { command -v "$1" &>/dev/null; }

# === 1. detect package manager and install tools ===
echo ""
echo "Checking tools..."

# macOS: ensure Homebrew is in PATH if installed but not yet visible
if [ "$OS" = "Darwin" ] && ! has_cmd brew; then
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -f /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

install_packages() {
  local packages=("$@")

  if command -v brew &>/dev/null; then
    brew install "${packages[@]}" 2>/dev/null || true
  elif command -v port &>/dev/null; then
    sudo port install "${packages[@]}" 2>/dev/null || true
  elif command -v nix-env &>/dev/null; then
    for pkg in "${packages[@]}"; do
      nix-env -iA "nixpkgs.$pkg" 2>/dev/null || true
    done
  elif command -v apt-get &>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq "${packages[@]}" 2>/dev/null || true
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y "${packages[@]}" 2>/dev/null || true
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm "${packages[@]}" 2>/dev/null || true
  elif command -v apk &>/dev/null; then
    sudo apk add "${packages[@]}" 2>/dev/null || true
  elif command -v zypper &>/dev/null; then
    sudo zypper install -y "${packages[@]}" 2>/dev/null || true
  else
    echo "No package manager found."
    echo "Please install manually: ${packages[*]}"
    return 1
  fi
}

# install tmux via micromamba (no admin required, works on any macOS/Linux)
# uses conda-forge packages installed to ~/.batipanel/.mamba
install_via_mamba() {
  local pkg="$1"
  local mamba_root="$BATIPANEL_HOME/.mamba"
  local mamba_bin="$mamba_root/bin/micromamba"

  # install micromamba if not present
  if [ ! -x "$mamba_bin" ]; then
    echo "  Setting up package manager (no admin required)..."
    mkdir -p "$mamba_root/bin"
    local platform
    case "$OS" in
      Darwin)
        case "$(uname -m)" in
          arm64) platform="osx-arm64" ;;
          *)     platform="osx-64" ;;
        esac
        ;;
      *)
        case "$(uname -m)" in
          aarch64|arm64) platform="linux-aarch64" ;;
          ppc64le)       platform="linux-ppc64le" ;;
          *)             platform="linux-64" ;;
        esac
        ;;
    esac
    if ! curl -fsSL "https://micro.mamba.pm/api/micromamba/${platform}/latest" \
        | tar xj -C "$mamba_root/bin" --strip-components=1 bin/micromamba 2>/dev/null; then
      echo "  Failed to download micromamba"
      return 1
    fi
    chmod +x "$mamba_bin"
  fi

  # install package into base environment
  echo "  Installing $pkg..."
  "$mamba_bin" install -r "$mamba_root" -n base -c conda-forge -y "$pkg" 2>/dev/null || return 1

  # create wrapper script (sets library paths so conda binaries work)
  local installed_bin="$mamba_root/bin/$pkg"
  if [ ! -f "$installed_bin" ]; then
    installed_bin=$(find "$mamba_root" -name "$pkg" -type f -executable 2>/dev/null | head -1)
  fi
  if [ -n "$installed_bin" ] && [ -f "$installed_bin" ]; then
    mkdir -p "$BATIPANEL_HOME/bin"
    cat > "$BATIPANEL_HOME/bin/$pkg" << WRAPPER_EOF
#!/usr/bin/env bash
export DYLD_LIBRARY_PATH="$mamba_root/lib:\${DYLD_LIBRARY_PATH:-}"
export LD_LIBRARY_PATH="$mamba_root/lib:\${LD_LIBRARY_PATH:-}"
export TERMINFO_DIRS="$mamba_root/share/terminfo:\${TERMINFO_DIRS:-}"
exec "$installed_bin" "\$@"
WRAPPER_EOF
    chmod +x "$BATIPANEL_HOME/bin/$pkg"
    export PATH="$BATIPANEL_HOME/bin:$PATH"
    echo "  Installed $pkg successfully"
    return 0
  fi
  return 1
}

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

if [ "$_tmux_smoke_ok" = "0" ]; then
  echo ""
  echo "WARNING: tmux is installed but fails to start (server exited unexpectedly)."
  # if mamba tmux exists, it may be the broken one — remove wrapper so brew takes priority
  if [ -f "$BATIPANEL_HOME/bin/tmux" ] && [ -d "$BATIPANEL_HOME/.mamba" ]; then
    echo "  Removing unstable conda-forge tmux..."
    rm -f "$BATIPANEL_HOME/bin/tmux"
  fi
  if [ "$OS" = "Darwin" ]; then
    echo "  Please install tmux via Homebrew:  brew install tmux"
  else
    echo "  Please install tmux via package manager:  sudo apt install tmux"
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

# optional tools: install via package manager first, fallback to GitHub releases
echo ""
echo "Installing optional tools..."

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  ARCH_GO="x86_64" ; ARCH_YAZI="x86_64" ;;
  aarch64|arm64) ARCH_GO="arm64" ; ARCH_YAZI="aarch64" ;;
  *) ARCH_GO="$ARCH" ; ARCH_YAZI="$ARCH" ;;
esac
OS_LOWER="$(uname -s | tr '[:upper:]' '[:lower:]')"

install_from_github() {
  local name="$1" url="$2" tmpdir
  tmpdir=$(mktemp -d)
  echo "  Downloading $name from GitHub..."
  if ! curl -fsSL "$url" -o "$tmpdir/archive"; then
    echo "  Failed to download $name"
    rm -rf "$tmpdir"
    return 1
  fi
  case "$url" in
    *.tar.gz|*.tgz)
      if ! tar xzf "$tmpdir/archive" -C "$tmpdir"; then
        echo "  Failed to extract $name"
        rm -rf "$tmpdir"
        return 1
      fi
      ;;
    *.zip)
      if ! has_cmd unzip; then
        echo "  Installing unzip..."
        install_packages unzip 2>/dev/null || true
      fi
      if ! unzip -qo "$tmpdir/archive" -d "$tmpdir"; then
        echo "  Failed to extract $name (is unzip installed?)"
        rm -rf "$tmpdir"
        return 1
      fi
      ;;
  esac
  local bin
  bin=$(find "$tmpdir" -name "$name" -type f 2>/dev/null | head -1)
  if [ -z "$bin" ]; then
    echo "  Binary '$name' not found in archive"
    rm -rf "$tmpdir"
    return 1
  fi
  chmod +x "$bin"
  # prefer user-local install (no admin required), fallback to system-wide
  if install "$bin" "$HOME/.local/bin/" 2>/dev/null; then
    echo "  Installed $name to ~/.local/bin/"
    NEED_LOCAL_BIN_PATH=1
  elif install "$bin" /usr/local/bin/ 2>/dev/null; then
    echo "  Installed $name to /usr/local/bin/"
  else
    echo "  Failed to install $name"
    rm -rf "$tmpdir"
    return 1
  fi
  rm -rf "$tmpdir"
}

latest_github_tag() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
    | grep -o '"tag_name": "[^"]*"' | head -1 | sed 's/.*: "//;s/"//' || echo ""
}

# ensure tool directories are in PATH for this script
NEED_LOCAL_BIN_PATH=0
mkdir -p "$HOME/.local/bin"
case ":$PATH:" in
  *":$BATIPANEL_HOME/bin:"*) ;;
  *) export PATH="$BATIPANEL_HOME/bin:$PATH" ;;
esac
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
case ":$PATH:" in
  *":$HOME/.claude/bin:"*) ;;
  *) export PATH="$HOME/.claude/bin:$PATH" ;;
esac

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

# === 2. create directory structure ===
mkdir -p "$BATIPANEL_HOME"/{bin,lib,layouts,projects,config}

# === 3. migrate existing ~/tmux/ ===
if [ -d "$HOME/tmux" ] && [ ! -f "$BATIPANEL_HOME/.migrated" ]; then
  echo ""
  echo "Migrating existing ~/tmux/ configuration..."

  # move project files (skip core/layout/example)
  for f in "$HOME"/tmux/*.sh; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .sh)
    case "$name" in
      common|start|layout_*|example) continue ;;
    esac
    if [ ! -f "$BATIPANEL_HOME/projects/$name.sh" ]; then
      cp "$f" "$BATIPANEL_HOME/projects/$name.sh"
      echo "  Migrated project: $name"
    fi
  done

  # update paths in migrated project files
  for f in "$BATIPANEL_HOME"/projects/*.sh; do
    [ -f "$f" ] || continue
    # shellcheck disable=SC2016
    sed_i 's|source ~/tmux/common.sh|BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"\nsource "$BATIPANEL_HOME/lib/common.sh"|g' "$f"
  done

  # preserve existing config.sh
  if [ -f "$HOME/tmux/config.sh" ] && [ ! -f "$BATIPANEL_HOME/config.sh" ]; then
    cp "$HOME/tmux/config.sh" "$BATIPANEL_HOME/config.sh"
    echo "  Preserved config: config.sh"
  fi

  touch "$BATIPANEL_HOME/.migrated"
  echo "  Migration complete"
fi

# === 4. copy scripts ===
echo ""
echo "Installing scripts..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cp "$SCRIPT_DIR/bin/start.sh" "$BATIPANEL_HOME/bin/"
for mod in common.sh core.sh logger.sh validate.sh layout.sh session.sh project.sh doctor.sh wizard.sh shell-setup.sh server-docker.sh server.sh server-init.sh themes-data.sh themes-tmux.sh themes-bash.sh themes.sh; do
  cp "$SCRIPT_DIR/lib/$mod" "$BATIPANEL_HOME/lib/"
done
cp "$SCRIPT_DIR/VERSION" "$BATIPANEL_HOME/VERSION" 2>/dev/null || true
cp "$SCRIPT_DIR/uninstall.sh" "$BATIPANEL_HOME/" 2>/dev/null || true

for layout in 4panel 5panel 6panel 7panel 7panel_log 8panel dual-claude devops; do
  cp "$SCRIPT_DIR/layouts/${layout}.sh" "$BATIPANEL_HOME/layouts/"
done

chmod +x "$BATIPANEL_HOME"/bin/*.sh "$BATIPANEL_HOME"/lib/*.sh "$BATIPANEL_HOME"/layouts/*.sh

# copy docker templates
if [ -d "$SCRIPT_DIR/docker" ]; then
  mkdir -p "$BATIPANEL_HOME/docker"/{templates,scripts}
  cp "$SCRIPT_DIR/docker/docker-compose.yml" "$BATIPANEL_HOME/docker/" 2>/dev/null || true
  cp "$SCRIPT_DIR/docker/templates/"* "$BATIPANEL_HOME/docker/templates/" 2>/dev/null || true
  cp "$SCRIPT_DIR/docker/scripts/"* "$BATIPANEL_HOME/docker/scripts/" 2>/dev/null || true
  chmod +x "$BATIPANEL_HOME/docker/scripts/"*.sh 2>/dev/null || true
fi

# copy examples
if [ -d "$SCRIPT_DIR/examples" ]; then
  mkdir -p "$BATIPANEL_HOME/examples"
  cp "$SCRIPT_DIR/examples/"*.sh "$BATIPANEL_HOME/examples/" 2>/dev/null || true
fi

# === 5. install completions ===
if [ -d "$SCRIPT_DIR/completions" ]; then
  mkdir -p "$BATIPANEL_HOME/completions"
  cp "$SCRIPT_DIR/completions/batipanel.bash" "$BATIPANEL_HOME/completions/" 2>/dev/null || true
  cp "$SCRIPT_DIR/completions/_batipanel.zsh" "$BATIPANEL_HOME/completions/" 2>/dev/null || true
fi

# === 6. install tmux.conf ===
mkdir -p "$BATIPANEL_HOME/config"
cp "$SCRIPT_DIR/config/tmux.conf" "$BATIPANEL_HOME/config/tmux.conf"
cp "$SCRIPT_DIR/config/tmux-powerline.conf" "$BATIPANEL_HOME/config/tmux-powerline.conf" 2>/dev/null || true

# generate platform-specific config (no if-shell needed — detected at install time)
_PLATFORM_CONF="$BATIPANEL_HOME/config/tmux-platform.conf"
{
  echo "# batipanel platform config (auto-generated by install.sh)"
  echo ""

  # clipboard
  case "$OS" in
    Darwin)
      echo "# macOS clipboard"
      echo "bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'pbcopy'"
      ;;
    *)
      if command -v xclip &>/dev/null; then
        echo "# Linux clipboard (xclip)"
        echo "bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -selection clipboard'"
      elif grep -qi microsoft /proc/version 2>/dev/null; then
        echo "# WSL clipboard"
        echo "bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'clip.exe'"
      fi
      ;;
  esac

  # default shell
  local_shell="${SHELL:-}"
  if [ -n "$local_shell" ] && [ -x "$local_shell" ]; then
    echo ""
    echo "# user shell"
    echo "set -g default-shell \"$local_shell\""
  fi

  echo ""
  echo "# theme overlay (generated by 'b theme')"
  echo "source-file $BATIPANEL_HOME/config/theme.conf"
} > "$_PLATFORM_CONF"
echo "  Generated platform config"

# guarantee theme.conf exists (empty = no theme = default tmux colors)
if [ ! -f "$BATIPANEL_HOME/config/theme.conf" ]; then
  echo "# batipanel theme (auto-generated, use 'b theme' to change)" > "$BATIPANEL_HOME/config/theme.conf"
fi

# kill stale tmux server so new config takes effect
tmux kill-server 2>/dev/null || true

# clean ~/.tmux.conf (remove ALL old batipanel lines, then add fresh)
BATIPANEL_SOURCE_LINE="source-file $BATIPANEL_HOME/config/tmux.conf"
if [ -f ~/.tmux.conf ]; then
  sed_i '/batipanel/d' ~/.tmux.conf 2>/dev/null || true
fi
{
  echo ""
  echo "# batipanel"
  echo "$BATIPANEL_SOURCE_LINE"
} >> ~/.tmux.conf
echo "  Configured ~/.tmux.conf"

# === 7. register aliases ===
# detect user's login shell via $SHELL (not $BASH_VERSION which reflects the script interpreter)
USER_SHELL="$(basename "${SHELL:-/bin/bash}")"
case "$USER_SHELL" in
  zsh)
    SHELL_RC="$HOME/.zshrc"
    ;;
  bash)
    if [ -f "$HOME/.bashrc" ]; then
      SHELL_RC="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
      SHELL_RC="$HOME/.bash_profile"
    else
      SHELL_RC="$HOME/.profile"
    fi
    ;;
  *)
    # fallback: check which RC files exist
    if [ -f "$HOME/.zshrc" ]; then
      SHELL_RC="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
      SHELL_RC="$HOME/.bashrc"
    else
      SHELL_RC="$HOME/.profile"
    fi
    ;;
esac

BATIPANEL_ALIAS="alias batipanel='bash \"$BATIPANEL_HOME/bin/start.sh\"'"
# b is a function (not alias) so theme changes can auto-reload the prompt
SHORT_FUNC="b() { bash \"$BATIPANEL_HOME/bin/start.sh\" \"\$@\"; if [[ \"\${1:-}\" == \"theme\" || (\"\${1:-}\" == \"config\" && \"\${2:-}\" == \"theme\") ]]; then if [ -n \"\${ZSH_VERSION:-}\" ]; then local _pf=\"$BATIPANEL_HOME/config/zsh-prompt.zsh\"; [ -f \"\$_pf\" ] && source \"\$_pf\"; else local _pf=\"$BATIPANEL_HOME/config/bash-prompt.sh\"; [ -f \"\$_pf\" ] && source \"\$_pf\"; fi; fi; }"

# Always register 'batipanel' alias
if grep -q "alias batipanel=" "$SHELL_RC" 2>/dev/null; then
  sed_i "s|alias batipanel=.*|$BATIPANEL_ALIAS|" "$SHELL_RC"
else
  {
    echo ""
    echo "# batipanel - AI workspace manager"
    echo "$BATIPANEL_ALIAS"
  } >> "$SHELL_RC"
fi
echo "  Added alias: batipanel ($SHELL_RC)"

# Register short command 'b' as function (auto-reloads prompt on theme change)
# migrate: remove old alias format
if grep -q "alias b=.*batipanel" "$SHELL_RC" 2>/dev/null; then
  sed_i "/alias b=.*batipanel/d" "$SHELL_RC"
fi
# update or add function
if grep -qF "b() {" "$SHELL_RC" 2>/dev/null && grep -q "batipanel" "$SHELL_RC" 2>/dev/null; then
  sed_i "/b() {.*batipanel/d" "$SHELL_RC"
  echo "$SHORT_FUNC" >> "$SHELL_RC"
  echo "  Updated command: b ($SHELL_RC)"
elif grep -q "alias b=" "$SHELL_RC" 2>/dev/null; then
  # 'b' alias exists from another tool — skip
  echo "  Skipped 'b' — already defined in $SHELL_RC"
  echo "  You can add it manually: $SHORT_FUNC"
else
  echo "$SHORT_FUNC" >> "$SHELL_RC"
  echo "  Added command: b ($SHELL_RC)"
fi

# === 8. persist tool paths in shell RC ===
# ~/.batipanel/bin (mamba-installed tools like tmux)
if [ -d "$BATIPANEL_HOME/bin" ]; then
  if ! grep -qF '.batipanel/bin' "$SHELL_RC" 2>/dev/null; then
    echo 'export PATH="$HOME/.batipanel/bin:$PATH"' >> "$SHELL_RC"
    echo "  Added ~/.batipanel/bin to PATH ($SHELL_RC)"
  fi
fi

# ~/.claude/bin (Claude Code native installer location)
if [ -d "$HOME/.claude/bin" ]; then
  if ! grep -qF '.claude/bin' "$SHELL_RC" 2>/dev/null; then
    echo 'export PATH="$HOME/.claude/bin:$PATH"' >> "$SHELL_RC"
    echo "  Added ~/.claude/bin to PATH ($SHELL_RC)"
  fi
fi

# ~/.local/bin (GitHub-installed tools)
if [ "$NEED_LOCAL_BIN_PATH" = "1" ]; then
  if ! grep -qF '.local/bin' "$SHELL_RC" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    echo "  Added ~/.local/bin to PATH ($SHELL_RC)"
  fi
fi

# === 9. register tab completion ===
if [ "$USER_SHELL" = "zsh" ]; then
  # zsh: install completion + ensure compinit runs
  local_zsh_comp="${ZDOTDIR:-$HOME}/.zfunc"
  mkdir -p "$local_zsh_comp"
  if [ -f "$BATIPANEL_HOME/completions/_batipanel.zsh" ]; then
    cp "$BATIPANEL_HOME/completions/_batipanel.zsh" "$local_zsh_comp/_batipanel"
    # also copy as _b so completion works for the 'b' function
    cp "$BATIPANEL_HOME/completions/_batipanel.zsh" "$local_zsh_comp/_b"
    if ! grep -qF "$local_zsh_comp" "$SHELL_RC" 2>/dev/null; then
      echo "fpath+=($local_zsh_comp)" >> "$SHELL_RC"
    fi
    # ensure compinit is loaded (needed for fpath completions)
    if ! grep -qF "compinit" "$SHELL_RC" 2>/dev/null; then
      echo 'autoload -Uz compinit && compinit -C' >> "$SHELL_RC"
    fi
    echo "  Added zsh completion"
  fi
else
  # bash: source completion script
  COMP_SOURCE="source \"$BATIPANEL_HOME/completions/batipanel.bash\""
  if [ -f "$BATIPANEL_HOME/completions/batipanel.bash" ]; then
    if ! grep -qF "completions/batipanel" "$SHELL_RC" 2>/dev/null; then
      echo "$COMP_SOURCE" >> "$SHELL_RC"
      echo "  Added tab completion ($SHELL_RC)"
    fi
  fi
fi

# === 9b. install Nerd Font + recommend iTerm2 (macOS) ===
if [ "$OS" = "Darwin" ]; then
  echo ""

  # install Nerd Font
  if command -v brew &>/dev/null; then
    if ! brew list --cask font-meslo-lg-nerd-font &>/dev/null 2>&1; then
      echo "Installing Nerd Font (MesloLGS NF) for powerline glyphs..."
      brew install --cask font-meslo-lg-nerd-font 2>/dev/null || true
    fi
  fi

  # recommend iTerm2 if not installed and user is on Apple Terminal
  if [ "${TERM_PROGRAM:-}" = "Apple_Terminal" ]; then
    # check if iTerm2 is already installed
    if [ ! -d "/Applications/iTerm.app" ]; then
      echo "Recommended: install iTerm2 for full theme & color support."
      if command -v brew &>/dev/null; then
        echo "  brew install --cask iterm2"
      else
        echo "  https://iterm2.com/downloads.html"
      fi
    else
      echo "iTerm2 is installed. Use iTerm2 for the best experience."
    fi
  fi
fi

# === 10. setup shell environment (powerline fonts, prompt theme) ===
# _sed_i is needed by shell-setup.sh (reuse install.sh's sed_i)
_sed_i() { sed_i "$@"; }
export -f _sed_i 2>/dev/null || true

# source theme modules so _generate_themed_prompt is available
# shellcheck source=lib/core.sh
source "$BATIPANEL_HOME/lib/core.sh"
# shellcheck source=lib/themes-data.sh
source "$BATIPANEL_HOME/lib/themes-data.sh"
# shellcheck source=lib/themes-tmux.sh
source "$BATIPANEL_HOME/lib/themes-tmux.sh"
# shellcheck source=lib/themes-bash.sh
source "$BATIPANEL_HOME/lib/themes-bash.sh"
# shellcheck source=lib/shell-setup.sh
source "$BATIPANEL_HOME/lib/shell-setup.sh"

# apply default theme (generates theme.conf, bash-prompt.sh, theme-env.sh)
BATIPANEL_THEME="${BATIPANEL_THEME:-default}"
_generate_theme_conf "$BATIPANEL_THEME"
generate_theme_env "$BATIPANEL_THEME"

# setup shell RC (sources prompt file from .bashrc/.zshrc)
setup_shell_environment "$USER_SHELL" "$SHELL_RC"

# === done ===
echo ""
echo "batipanel installed successfully!"
echo "  Location: $BATIPANEL_HOME"
echo ""

# Report missing tools
if ! command -v claude &>/dev/null; then
  echo "WARNING: Claude Code is not installed (core dependency)"
  echo "  Install: curl -fsSL https://claude.ai/install.sh | bash"
  echo ""
fi

MISSING=()
command -v lazygit &>/dev/null || MISSING+=("lazygit")
command -v btop &>/dev/null   || MISSING+=("btop")
command -v yazi &>/dev/null   || MISSING+=("yazi")
command -v eza &>/dev/null    || MISSING+=("eza")
if [ ${#MISSING[@]} -gt 0 ]; then
  echo "Optional tools not installed (will work without them):"
  for m in "${MISSING[@]}"; do
    echo "  - $m"
  done
  if [[ "$(uname -s)" == "Linux" ]] && command -v apt-get &>/dev/null; then
    echo ""
    echo "  On Ubuntu/Debian, some tools need manual installation:"
    echo "    lazygit: https://github.com/jesseduffield/lazygit#installation"
    echo "    yazi:    https://github.com/sxyazi/yazi#installation"
    echo "    eza:     https://github.com/eza-community/eza#installation"
  fi
  echo ""
fi

echo "Usage:"
echo "  b myproject                  # Start or resume a project"
echo "  b myproject --layout 6panel  # Start with specific layout"
echo "  b new <name> <path>          # Register a new project"
echo "  b stop myproject             # Stop a session"
echo "  b ls                         # List sessions & projects"
echo "  b layouts                    # Show available layouts"
echo "  b config layout 7panel       # Change default layout"
echo "  b theme                      # List/change color themes"
echo ""
if [ "${TERM_PROGRAM:-}" = "Apple_Terminal" ]; then
  echo "** Apple Terminal does not support background color themes. **"
  echo ""
  if [ -d "/Applications/iTerm.app" ]; then
    echo "Next steps:"
    echo "  1. Open iTerm2"
    echo "  2. Set font: iTerm2 > Settings > Profiles > Text > Font > MesloLGS NF"
    echo "  3. Type: b"
  else
    echo "Next steps:"
    echo "  1. Install iTerm2:"
    if command -v brew &>/dev/null; then
      echo "     brew install --cask iterm2"
    else
      echo "     https://iterm2.com/downloads.html"
    fi
    echo "  2. Open iTerm2"
    echo "  3. Set font: iTerm2 > Settings > Profiles > Text > Font > MesloLGS NF"
    echo "  4. Type: b"
  fi
else
  echo "Tip: Set your terminal font to a Nerd Font (e.g. MesloLGS NF)"
  echo "     for powerline arrow-style prompt glyphs."
  echo ""
  echo "Open a new terminal window, then type: b"
fi
