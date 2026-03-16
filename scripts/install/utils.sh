#!/usr/bin/env bash
# scripts/install/utils.sh - portable helpers: sed_i, has_cmd, package managers, GitHub tools, PATH setup

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
  elif command -v yum &>/dev/null; then
    sudo yum install -y "${packages[@]}" 2>/dev/null || true
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
    # shellcheck disable=SC2034
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
setup_install_paths() {
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
}
