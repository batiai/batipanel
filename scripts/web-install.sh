#!/usr/bin/env bash
# batipanel web installer — one-line install script
# Usage: curl -fsSL https://batipanel.com/install.sh | bash
#
# This script:
#   1. Downloads the latest batipanel release
#   2. Runs the full installer (install.sh)
#   3. Cleans up temporary files

set -euo pipefail

REPO="https://github.com/batiai/batipanel"
BRANCH="master"

# colors (respect NO_COLOR: https://no-color.org)
if [[ -z "${NO_COLOR:-}" ]] && [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED='' GREEN='' BLUE='' NC=''
fi

info()  { echo -e "${BLUE}[batipanel]${NC} $*"; }
ok()    { echo -e "${GREEN}[batipanel]${NC} $*"; }
fail()  { echo -e "${RED}[batipanel]${NC} $*" >&2; exit 1; }

# check minimum requirements
command -v bash &>/dev/null || fail "bash is required"

# create temp directory
TMPDIR_INSTALL="$(mktemp -d)"
cleanup() { rm -rf "$TMPDIR_INSTALL"; }
trap cleanup EXIT

info "Downloading batipanel..."

# prefer git clone, fallback to tarball download
if command -v git &>/dev/null; then
  git clone --depth 1 --branch "$BRANCH" "$REPO.git" "$TMPDIR_INSTALL/batipanel" 2>/dev/null \
    || fail "Failed to clone repository. Check your internet connection."
elif command -v curl &>/dev/null; then
  curl -fsSL "$REPO/archive/refs/heads/${BRANCH}.tar.gz" -o "$TMPDIR_INSTALL/batipanel.tar.gz" \
    || fail "Failed to download. Check your internet connection."
  mkdir -p "$TMPDIR_INSTALL/batipanel"
  tar xzf "$TMPDIR_INSTALL/batipanel.tar.gz" -C "$TMPDIR_INSTALL/batipanel" --strip-components=1 \
    || fail "Failed to extract archive."
elif command -v wget &>/dev/null; then
  wget -qO "$TMPDIR_INSTALL/batipanel.tar.gz" "$REPO/archive/refs/heads/${BRANCH}.tar.gz" \
    || fail "Failed to download. Check your internet connection."
  mkdir -p "$TMPDIR_INSTALL/batipanel"
  tar xzf "$TMPDIR_INSTALL/batipanel.tar.gz" -C "$TMPDIR_INSTALL/batipanel" --strip-components=1 \
    || fail "Failed to extract archive."
else
  fail "git, curl, or wget is required. Install one and try again."
fi

ok "Downloaded successfully."
echo ""

# run the real installer with /dev/tty as stdin
# (curl | bash consumes stdin, so interactive prompts need /dev/tty)
cd "$TMPDIR_INSTALL/batipanel"
bash install.sh </dev/tty

# cleanup happens via trap
