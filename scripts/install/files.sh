#!/usr/bin/env bash
# scripts/install/files.sh - create dirs, migrate ~/tmux, copy scripts/layouts/docker/examples, completions

# === 2. create directory structure ===
# === 3. migrate existing ~/tmux/ ===
# === 4. copy scripts ===
# === 5. install completions ===

copy_files() {
  mkdir -p "$BATIPANEL_HOME"/{bin,lib,layouts,projects,config}

  # migrate existing ~/tmux/
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

  # copy scripts
  echo ""
  echo "Installing scripts..."

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

  # copy btop compact config (cpu+proc only for multi-panel layouts)
  if [ -d "$SCRIPT_DIR/config/btop" ]; then
    mkdir -p "$BATIPANEL_HOME/config/btop"
    cp "$SCRIPT_DIR/config/btop/btop.conf" "$BATIPANEL_HOME/config/btop/" 2>/dev/null || true
  fi

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
}

install_completions() {
  if [ -d "$SCRIPT_DIR/completions" ]; then
    mkdir -p "$BATIPANEL_HOME/completions"
    cp "$SCRIPT_DIR/completions/batipanel.bash" "$BATIPANEL_HOME/completions/" 2>/dev/null || true
    cp "$SCRIPT_DIR/completions/_batipanel.zsh" "$BATIPANEL_HOME/completions/" 2>/dev/null || true
  fi
}
