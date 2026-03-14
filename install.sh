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

# required: tmux
if ! command -v tmux &>/dev/null; then
  echo "Installing tmux..."
  install_packages tmux 2>/dev/null || true
fi

if ! command -v tmux &>/dev/null; then
  echo ""
  echo "tmux is required but could not be installed automatically."
  echo ""
  echo "Install tmux using any of these methods:"
  case "$OS" in
    Darwin)
      echo "  # Homebrew (most common)"
      echo "  brew install tmux"
      echo ""
      echo "  # MacPorts"
      echo "  sudo port install tmux"
      echo ""
      echo "  # Nix (no admin required)"
      echo "  curl -L https://nixos.org/nix/install | sh && nix-env -iA nixpkgs.tmux"
      ;;
    *)
      echo "  Ubuntu/Debian:  sudo apt install tmux"
      echo "  Fedora/RHEL:    sudo dnf install tmux"
      echo "  Arch:           sudo pacman -S tmux"
      echo "  Alpine:         sudo apk add tmux"
      echo "  openSUSE:       sudo zypper install tmux"
      echo "  Nix:            nix-env -iA nixpkgs.tmux"
      ;;
  esac
  echo ""
  echo "After installing tmux, re-run this installer."
  exit 1
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
  if sudo install "$bin" /usr/local/bin/ 2>/dev/null; then
    echo "  Installed $name to /usr/local/bin/"
  elif install "$bin" "$HOME/.local/bin/" 2>/dev/null; then
    echo "  Installed $name to ~/.local/bin/"
    NEED_LOCAL_BIN_PATH=1
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

BATIPANEL_SOURCE_LINE="source-file $BATIPANEL_HOME/config/tmux.conf"
if [ -f ~/.tmux.conf ]; then
  if ! grep -qF "$BATIPANEL_SOURCE_LINE" ~/.tmux.conf 2>/dev/null; then
    {
      echo ""
      echo "# batipanel"
      echo "$BATIPANEL_SOURCE_LINE"
    } >> ~/.tmux.conf
    echo "  Added batipanel source line to ~/.tmux.conf"
  else
    echo "  ~/.tmux.conf already configured"
  fi
else
  echo "# batipanel" > ~/.tmux.conf
  echo "$BATIPANEL_SOURCE_LINE" >> ~/.tmux.conf
  echo "  Created ~/.tmux.conf with batipanel source"
fi

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
SHORT_FUNC="b() { bash \"$BATIPANEL_HOME/bin/start.sh\" \"\$@\"; if [[ \"\${1:-}\" == \"theme\" || (\"\${1:-}\" == \"config\" && \"\${2:-}\" == \"theme\") ]]; then local _pf=\"$BATIPANEL_HOME/config/bash-prompt.sh\"; [ -f \"\$_pf\" ] && source \"\$_pf\"; fi; }"

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
  # zsh: install via fpath (not bash source)
  local_zsh_comp="${ZDOTDIR:-$HOME}/.zfunc"
  mkdir -p "$local_zsh_comp"
  if [ -f "$BATIPANEL_HOME/completions/_batipanel.zsh" ]; then
    cp "$BATIPANEL_HOME/completions/_batipanel.zsh" "$local_zsh_comp/_batipanel"
    if ! grep -qF "$local_zsh_comp" "$SHELL_RC" 2>/dev/null; then
      echo "fpath+=($local_zsh_comp)" >> "$SHELL_RC"
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

# === 10. setup shell environment (powerline fonts, prompt theme) ===
# _sed_i is needed by shell-setup.sh (reuse install.sh's sed_i)
_sed_i() { sed_i "$@"; }
export -f _sed_i 2>/dev/null || true

# source shell-setup and run
# shellcheck source=lib/shell-setup.sh
source "$BATIPANEL_HOME/lib/shell-setup.sh"
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
# auto-apply: start a fresh shell so aliases are immediately available
if [ -t 0 ]; then
  printf "Start a new shell to apply changes? [Y/n] "
  read -r yn
  case "${yn:-Y}" in
    [Yy]*|"")
      echo "Starting $USER_SHELL..."
      exec "$SHELL" -l
      ;;
    *)
      echo "Run this to apply: source $SHELL_RC"
      ;;
  esac
else
  echo "Open a new terminal or run: source $SHELL_RC"
fi
