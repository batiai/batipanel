#!/usr/bin/env bash
# install.sh - batipanel 설치 스크립트 (macOS / Linux)

set -euo pipefail

BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"

echo "batipanel - Setting up AI development workspace..."

# OS 감지
OS="$(uname -s)"

# portable sed -i (macOS vs GNU)
sed_i() {
  if [ "$OS" = "Darwin" ]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# === 1. 패키지 매니저 감지 및 도구 설치 ===
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

# 필수: tmux
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

# 선택: lazygit, eza, btop (없어도 동작함)
echo ""
echo "Installing optional tools (will work without them)..."

# lazygit — 패키지 매니저마다 이름이 다를 수 있음
if ! command -v lazygit &>/dev/null; then
  install_packages lazygit 2>/dev/null || true
fi

# btop
if ! command -v btop &>/dev/null; then
  install_packages btop 2>/dev/null || true
fi

# yazi — TUI 파일 매니저 (파일 탐색/미리보기)
if ! command -v yazi &>/dev/null; then
  install_packages yazi 2>/dev/null || true
fi

# eza — 일부 배포판에서는 아직 패키지가 없음
if ! command -v eza &>/dev/null; then
  install_packages eza 2>/dev/null || true
fi

# === 2. 디렉토리 구조 생성 ===
mkdir -p "$BATIPANEL_HOME"/{bin,lib,layouts,projects}

# === 3. 기존 ~/tmux/ 마이그레이션 ===
if [ -d "$HOME/tmux" ] && [ ! -f "$BATIPANEL_HOME/.migrated" ]; then
  echo ""
  echo "Migrating existing ~/tmux/ configuration..."

  # 프로젝트 파일 이동 (코어/레이아웃/예제 제외)
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

  # 마이그레이션된 프로젝트 파일 내 경로 업데이트
  for f in "$BATIPANEL_HOME"/projects/*.sh; do
    [ -f "$f" ] || continue
    # shellcheck disable=SC2016
    sed_i 's|source ~/tmux/common.sh|BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"\nsource "$BATIPANEL_HOME/lib/common.sh"|g' "$f"
  done

  # 기존 config.sh 보존
  if [ -f "$HOME/tmux/config.sh" ] && [ ! -f "$BATIPANEL_HOME/config.sh" ]; then
    cp "$HOME/tmux/config.sh" "$BATIPANEL_HOME/config.sh"
    echo "  Preserved config: config.sh"
  fi

  touch "$BATIPANEL_HOME/.migrated"
  echo "  Migration complete"
fi

# === 4. 스크립트 복사 ===
echo ""
echo "Installing scripts..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cp "$SCRIPT_DIR/bin/start.sh" "$BATIPANEL_HOME/bin/"
cp "$SCRIPT_DIR/lib/common.sh" "$BATIPANEL_HOME/lib/"
cp "$SCRIPT_DIR/VERSION" "$BATIPANEL_HOME/VERSION" 2>/dev/null || true

for layout in 4panel 5panel 6panel 7panel 7panel_log 8panel dual-claude devops; do
  cp "$SCRIPT_DIR/layouts/${layout}.sh" "$BATIPANEL_HOME/layouts/"
done

chmod +x "$BATIPANEL_HOME"/bin/*.sh "$BATIPANEL_HOME"/lib/*.sh "$BATIPANEL_HOME"/layouts/*.sh

# === 5. tmux.conf 설치 ===
mkdir -p "$BATIPANEL_HOME/config"
cp "$SCRIPT_DIR/config/tmux.conf" "$BATIPANEL_HOME/config/tmux.conf"

BATIPANEL_SOURCE_LINE="source-file $BATIPANEL_HOME/config/tmux.conf"
if [ -f ~/.tmux.conf ]; then
  if ! grep -qF "$BATIPANEL_SOURCE_LINE" ~/.tmux.conf 2>/dev/null; then
    echo "" >> ~/.tmux.conf
    echo "# batipanel" >> ~/.tmux.conf
    echo "$BATIPANEL_SOURCE_LINE" >> ~/.tmux.conf
    echo "  Added batipanel source line to ~/.tmux.conf"
  else
    echo "  ~/.tmux.conf already configured"
  fi
else
  echo "# batipanel" > ~/.tmux.conf
  echo "$BATIPANEL_SOURCE_LINE" >> ~/.tmux.conf
  echo "  Created ~/.tmux.conf with batipanel source"
fi

# === 6. alias 등록 ===
# 셸 RC 파일 감지
if [ -n "${ZSH_VERSION:-}" ] || [ -f "$HOME/.zshrc" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then
  SHELL_RC="$HOME/.bash_profile"
else
  SHELL_RC="$HOME/.profile"
fi

BATIPANEL_ALIAS="alias batipanel='bash $BATIPANEL_HOME/bin/start.sh'"
SHORT_ALIAS="alias b='bash $BATIPANEL_HOME/bin/start.sh'"

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

# === 완료 ===
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
echo "Open a new terminal or run: source $SHELL_RC"
