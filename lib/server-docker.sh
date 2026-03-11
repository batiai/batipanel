#!/usr/bin/env bash
# batipanel server-docker - Docker auto-install and dependency management

# Install Docker Engine/Desktop automatically
_install_docker() {
  local OS
  OS="$(uname -s)"

  case "$OS" in
    Darwin)
      if has_cmd brew; then
        echo "  Installing Docker via Homebrew..."
        brew install --cask docker 2>/dev/null || {
          echo -e "${RED}  Homebrew install failed.${NC}"
          echo "  Install manually: https://docs.docker.com/desktop/install/mac-install/"
          return 1
        }
        echo -e "  ${GREEN}✓${NC} Docker Desktop installed"
        echo ""
        echo -e "  ${YELLOW}Please open Docker Desktop from Applications, then re-run this command.${NC}"
        return 1
      else
        echo -e "${RED}  Homebrew not found. Install Docker Desktop manually:${NC}"
        echo "  https://docs.docker.com/desktop/install/mac-install/"
        return 1
      fi
      ;;
    Linux)
      echo "  Installing Docker Engine..."

      # official convenience script (Ubuntu, Debian, Fedora, CentOS, etc.)
      if has_cmd curl; then
        curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
      elif has_cmd wget; then
        wget -qO /tmp/get-docker.sh https://get.docker.com
      else
        echo -e "${RED}  curl or wget required to install Docker.${NC}"
        return 1
      fi

      if ! sudo sh /tmp/get-docker.sh 2>&1 | tail -5; then
        rm -f /tmp/get-docker.sh
        echo -e "${RED}  Docker installation failed.${NC}"
        echo "  Install manually: https://docs.docker.com/engine/install/"
        return 1
      fi
      rm -f /tmp/get-docker.sh

      # add current user to docker group
      if ! groups "$USER" 2>/dev/null | grep -qw docker; then
        sudo usermod -aG docker "$USER" 2>/dev/null || true
        echo -e "  ${YELLOW}Added $USER to docker group.${NC}"
        echo -e "  ${YELLOW}Log out and back in, or run: newgrp docker${NC}"
      fi

      # start and enable docker service
      if has_cmd systemctl; then
        sudo systemctl start docker 2>/dev/null || true
        sudo systemctl enable docker 2>/dev/null || true
      fi

      echo -e "  ${GREEN}✓${NC} Docker Engine installed"
      ;;
    *)
      echo -e "${RED}  Unsupported OS: $OS${NC}"
      echo "  Install Docker manually: https://docs.docker.com/engine/install/"
      return 1
      ;;
  esac
}

# Install Docker Compose plugin (Linux only)
_install_compose_plugin() {
  local compose_arch
  case "$(uname -m)" in
    x86_64)        compose_arch="x86_64" ;;
    aarch64|arm64) compose_arch="aarch64" ;;
    *)             compose_arch="$(uname -m)" ;;
  esac

  local compose_url="https://github.com/docker/compose/releases/latest/download/docker-compose-linux-${compose_arch}"
  local plugin_dir="${DOCKER_CONFIG:-$HOME/.docker}/cli-plugins"
  mkdir -p "$plugin_dir"

  echo "  Downloading Docker Compose plugin..."
  if curl -fsSL "$compose_url" -o "$plugin_dir/docker-compose" 2>/dev/null; then
    chmod +x "$plugin_dir/docker-compose"
    if docker compose version &>/dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} Docker Compose plugin installed"
      return 0
    fi
  fi

  echo -e "${RED}  Failed to install Docker Compose.${NC}"
  echo "  Install: https://docs.docker.com/compose/install/"
  return 1
}

# Ensure Docker + Compose are available and running
_require_docker() {
  # 1. check docker binary, auto-install if missing
  if ! has_cmd docker; then
    echo -e "${YELLOW}Docker is not installed.${NC}"
    if [ -t 0 ]; then
      printf "  Install Docker automatically? [Y/n]: "
      local yn
      read -r yn
      yn="${yn:-Y}"
      if [[ "$yn" =~ ^[Yy] ]]; then
        _install_docker || return 1
      else
        echo "  Skipped. Install Docker manually and try again."
        return 1
      fi
    else
      echo "  Install Docker: https://docs.docker.com/engine/install/"
      return 1
    fi
  fi

  # 2. check docker daemon is running, try to start
  if ! docker info &>/dev/null; then
    echo -e "${YELLOW}Docker is not running.${NC}"
    if has_cmd systemctl; then
      echo "  Starting Docker..."
      sudo systemctl start docker 2>/dev/null || true
      sleep 2
      if docker info &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Docker started"
      else
        echo -e "${RED}  Could not start Docker.${NC}"
        echo "  Start manually: sudo systemctl start docker"
        return 1
      fi
    elif [ "$(uname -s)" = "Darwin" ]; then
      echo "  Open Docker Desktop from Applications and try again."
      return 1
    else
      echo "  Start Docker and try again."
      return 1
    fi
  fi

  # 3. check docker compose, auto-install plugin if missing
  if ! docker compose version &>/dev/null 2>&1 && ! has_cmd docker-compose; then
    echo -e "${YELLOW}Docker Compose not found.${NC}"
    if [ "$(uname -s)" = "Linux" ]; then
      _install_compose_plugin || return 1
    else
      echo "  Install: https://docs.docker.com/compose/install/"
      return 1
    fi
  fi
}
