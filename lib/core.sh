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

# load config (safe key-value parser — never sources the file)
TMUX_CONFIG="$BATIPANEL_HOME/config.sh"
# shellcheck disable=SC2034  # used by layout/session modules
DEFAULT_LAYOUT="7panel"
if [ -f "$TMUX_CONFIG" ]; then
  while IFS='=' read -r _cfg_key _cfg_val; do
    # strip whitespace and quotes
    _cfg_key="${_cfg_key//[[:space:]]/}"
    _cfg_val="${_cfg_val%\"}" ; _cfg_val="${_cfg_val#\"}"
    _cfg_val="${_cfg_val%\'}" ; _cfg_val="${_cfg_val#\'}"
    # only accept known keys with safe values
    case "$_cfg_key" in
      DEFAULT_LAYOUT)
        if [[ "$_cfg_val" =~ ^[a-zA-Z0-9_-]+$ ]]; then
          # shellcheck disable=SC2034
          DEFAULT_LAYOUT="$_cfg_val"
        fi
        ;;
      BATIPANEL_ICONS)
        if [[ "$_cfg_val" =~ ^[01]$ ]]; then
          # shellcheck disable=SC2034  # used by layout.sh run_filetree
          BATIPANEL_ICONS="$_cfg_val"
        fi
        ;;
    esac
  done < "$TMUX_CONFIG"
fi
