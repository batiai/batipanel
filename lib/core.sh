#!/usr/bin/env bash
# batipanel core - colors, utilities, config loading

BATIPANEL_HOME="${BATIPANEL_HOME:-$HOME/.batipanel}"
BATIPANEL_DEBUG="${BATIPANEL_DEBUG:-0}"

# portable sed -i (macOS vs GNU)
_sed_i() {
  if [ "$(uname -s)" = "Darwin" ]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# colors (respect NO_COLOR standard: https://no-color.org)
# shellcheck disable=SC2034  # used by other modules
if [[ -n "${NO_COLOR:-}" || -n "${BATIPANEL_NO_COLOR:-}" ]]; then
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
elif [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

debug_log() {
  [[ "$BATIPANEL_DEBUG" == "1" ]] && echo -e "${YELLOW}[debug]${NC} $*" >&2
  return 0
}

# load config (validate before sourcing)
TMUX_CONFIG="$BATIPANEL_HOME/config.sh"
# shellcheck disable=SC2034  # used by layout/session modules
DEFAULT_LAYOUT="7panel"
if [ -f "$TMUX_CONFIG" ]; then
  # safety: only source if file contains valid bash and only variable assignments
  if bash -n "$TMUX_CONFIG" 2>/dev/null; then
    # shellcheck source=/dev/null
    source "$TMUX_CONFIG"
  else
    echo -e "${YELLOW}Warning: config.sh has syntax errors, using defaults${NC}" >&2
  fi
fi
