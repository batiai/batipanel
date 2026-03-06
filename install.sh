#!/usr/bin/env bash
# install.sh - 한번만 실행하면 세팅 완료

set -euo pipefail

echo "tmux 개발환경 세팅 시작..."

# 1. 필수 도구 확인
echo ""
echo "도구 확인 중..."

if ! command -v brew &>/dev/null; then
  echo "Homebrew가 설치되어 있지 않습니다."
  echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  exit 1
fi

# 2. 필요한 도구 설치
echo ""
echo "도구 설치 중..."
brew install tmux lazygit eza btop 2>/dev/null || true

if command -v pip3 &>/dev/null; then
  pip3 install asitop --break-system-packages 2>/dev/null || true
fi

# 필수 도구 확인
if ! command -v tmux &>/dev/null; then
  echo "tmux 설치에 실패했습니다."
  exit 1
fi

# 3. ~/tmux 폴더 생성
mkdir -p ~/tmux

# 4. 스크립트 복사
echo ""
echo "스크립트 설치 중..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for script in common.sh layout_6panel.sh layout_7panel.sh layout_7panel_log.sh start.sh batios.sh cosrx.sh; do
  if [ -f "$SCRIPT_DIR/$script" ]; then
    cp "$SCRIPT_DIR/$script" ~/tmux/
  fi
done
chmod +x ~/tmux/*.sh

# 5. tmux.conf 설치
if [ -f ~/.tmux.conf ]; then
  cp ~/.tmux.conf ~/.tmux.conf.backup
  echo "  기존 tmux.conf -> ~/.tmux.conf.backup"
fi
cp "$SCRIPT_DIR/tmux.conf" ~/.tmux.conf

# 6. alias 등록
SHELL_RC="$HOME/.zshrc"
if [ -n "${BASH_VERSION:-}" ] && [ ! -n "${ZSH_VERSION:-}" ]; then
  SHELL_RC="$HOME/.bashrc"
fi

ALIAS_LINE="alias t='bash ~/tmux/start.sh'"
if ! grep -q "alias t=" "$SHELL_RC" 2>/dev/null; then
  {
    echo ""
    echo "# tmux 프로젝트 관리"
    echo "$ALIAS_LINE"
  } >> "$SHELL_RC"
  echo "  alias t 등록됨 ($SHELL_RC)"
else
  echo "  alias t 이미 등록됨"
fi

echo ""
echo "세팅 완료!"
echo ""
echo "사용법:"
echo "  t batios                    # batios 시작 or 복귀"
echo "  t batios --layout 6panel   # 레이아웃 지정"
echo "  t new 이름 경로             # 새 프로젝트 등록"
echo "  t stop batios               # 세션 종료"
echo "  t ls                        # 목록 확인"
echo "  t layouts                   # 레이아웃 목록"
echo "  t config layout 7panel     # 기본 레이아웃 변경"
echo ""
echo "새 터미널 열거나 source $SHELL_RC 실행 후 사용하세요"
