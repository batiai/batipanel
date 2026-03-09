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

install_packages() {
  local packages=("$@")

  if command -v brew &>/dev/null; then
    brew install "${packages[@]}" 2>/dev/null || true
  elif command -v apt-get &>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq "${packages[@]}" 2>/dev/null || true
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y "${packages[@]}" 2>/dev/null || true
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm "${packages[@]}" 2>/dev/null || true
  else
    echo "No package manager found."
    echo "Please install manually: ${packages[*]}"
    return 1
  fi
}

# required: tmux
if ! command -v tmux &>/dev/null; then
  echo "Installing tmux..."
  install_packages tmux || {
    echo ""
    echo "Failed to install tmux. Please install manually:"
    case "$OS" in
      Darwin) echo "  brew install tmux" ;;
      *)
        echo "  Ubuntu/Debian: sudo apt install tmux"
        echo "  Fedora:        sudo dnf install tmux"
        echo "  Arch:          sudo pacman -S tmux"
        ;;
    esac
    exit 1
  }
fi

if ! command -v tmux &>/dev/null; then
  echo "tmux installation failed."
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
      sudo add-apt-repository -y ppa:git-core/ppa 2>/dev/null || true
      sudo apt-get update -qq 2>/dev/null
      sudo apt-get install -y -qq git 2>/dev/null || true
      echo "  Git upgraded to $(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
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
  x86_64)  ARCH_GO="x86_64" ; ARCH_ALT="amd64" ; ARCH_YAZI="x86_64" ;;
  aarch64|arm64) ARCH_GO="arm64" ; ARCH_ALT="arm64" ; ARCH_YAZI="aarch64" ;;
  *) ARCH_GO="$ARCH" ; ARCH_ALT="$ARCH" ; ARCH_YAZI="$ARCH" ;;
esac
OS_LOWER="$(uname -s | tr '[:upper:]' '[:lower:]')"
OS_CAPITAL="$(uname -s)"

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

# ensure ~/.local/bin exists and is in PATH for this script
NEED_LOCAL_BIN_PATH=0
mkdir -p "$HOME/.local/bin"
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# btop
if ! has_cmd btop; then
  install_packages btop 2>/dev/null || true
fi

# lazygit
if ! has_cmd lazygit; then
  install_packages lazygit 2>/dev/null || true
fi
if ! has_cmd lazygit; then
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
    install_from_github eza \
      "https://github.com/eza-community/eza/releases/download/${tag}/eza_${ARCH_YAZI}-unknown-linux-gnu.tar.gz"
  fi
fi

# yazi
if ! has_cmd yazi; then
  install_packages yazi 2>/dev/null || true
fi
if ! has_cmd yazi; then
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
for mod in common.sh core.sh validate.sh layout.sh session.sh project.sh doctor.sh wizard.sh; do
  cp "$SCRIPT_DIR/lib/$mod" "$BATIPANEL_HOME/lib/"
done
cp "$SCRIPT_DIR/VERSION" "$BATIPANEL_HOME/VERSION" 2>/dev/null || true
cp "$SCRIPT_DIR/uninstall.sh" "$BATIPANEL_HOME/" 2>/dev/null || true

for layout in 4panel 5panel 6panel 7panel 7panel_log 8panel dual-claude devops; do
  cp "$SCRIPT_DIR/layouts/${layout}.sh" "$BATIPANEL_HOME/layouts/"
done

chmod +x "$BATIPANEL_HOME"/bin/*.sh "$BATIPANEL_HOME"/lib/*.sh "$BATIPANEL_HOME"/layouts/*.sh

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
SHORT_ALIAS="alias b='bash \"$BATIPANEL_HOME/bin/start.sh\"'"

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

# Register short alias 'b' if no conflict
if grep -q "alias b=" "$SHELL_RC" 2>/dev/null; then
  if grep -q "batipanel" "$SHELL_RC" && grep -q "alias b=.*batipanel" "$SHELL_RC" 2>/dev/null; then
    sed_i "s|alias b=.*|$SHORT_ALIAS|" "$SHELL_RC"
    echo "  Updated alias: b ($SHELL_RC)"
  else
    echo "  Skipped alias 'b' — already defined in $SHELL_RC"
    echo "  You can add it manually: $SHORT_ALIAS"
  fi
else
  echo "$SHORT_ALIAS" >> "$SHELL_RC"
  echo "  Added alias: b ($SHELL_RC)"
fi

# === 8. persist ~/.local/bin in PATH (for GitHub-installed tools) ===
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

# === done ===
echo ""
echo "batipanel installed successfully!"
echo "  Location: $BATIPANEL_HOME"
echo ""

# Report missing optional tools
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
  # show install links for tools not in default repos
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
