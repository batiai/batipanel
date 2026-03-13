#!/usr/bin/env bash
# test helper - shared setup for all bats tests

# setup a temporary BATIPANEL_HOME for testing
setup_batipanel_env() {
  export BATIPANEL_HOME="$(mktemp -d)"
  export BATIPANEL_DEBUG="0"
  export NO_COLOR="1"

  # create minimal directory structure
  mkdir -p "$BATIPANEL_HOME"/{lib,bin,layouts,projects,config,logs}

  # copy lib modules
  local src_dir
  src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  for f in "$src_dir"/lib/*.sh; do
    cp "$f" "$BATIPANEL_HOME/lib/"
  done

  # copy layouts
  for f in "$src_dir"/layouts/*.sh; do
    [ -f "$f" ] && cp "$f" "$BATIPANEL_HOME/layouts/"
  done

  # copy VERSION
  cp "$src_dir/VERSION" "$BATIPANEL_HOME/VERSION" 2>/dev/null || echo "0.0.0-test" > "$BATIPANEL_HOME/VERSION"
}

teardown_batipanel_env() {
  if [ -n "${BATIPANEL_HOME:-}" ] && [[ "$BATIPANEL_HOME" == /tmp/* ]]; then
    rm -rf "$BATIPANEL_HOME"
  fi
}

# source modules in correct order (like common.sh does)
load_batipanel_modules() {
  source "$BATIPANEL_HOME/lib/core.sh"
  source "$BATIPANEL_HOME/lib/logger.sh"
  source "$BATIPANEL_HOME/lib/validate.sh"
}
