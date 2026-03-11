# bash completion for batipanel (b)
_batipanel() {
  local cur prev words cword
  _init_completion || return

  local home="${BATIPANEL_HOME:-$HOME/.batipanel}"

  # subcommands
  local commands="new reload stop ls list layouts config theme help doctor"

  # first argument: subcommand or project name
  if [[ $cword -eq 1 ]]; then
    local projects=""
    if [[ -d "$home/projects" ]]; then
      projects=$(find "$home/projects" -name '*.sh' -exec basename {} .sh \; 2>/dev/null)
    fi
    mapfile -t COMPREPLY < <(compgen -W "$commands $projects" -- "$cur")
    return
  fi

  case "${words[1]}" in
    new)
      # second arg: project name (no completion), third arg: directory
      if [[ $cword -eq 3 ]]; then
        _filedir -d
      fi
      ;;
    reload|stop)
      # complete project names
      if [[ $cword -eq 2 ]]; then
        local projects=""
        if [[ -d "$home/projects" ]]; then
          projects=$(find "$home/projects" -name '*.sh' -exec basename {} .sh \; 2>/dev/null)
        fi
        mapfile -t COMPREPLY < <(compgen -W "$projects" -- "$cur")
      fi
      ;;
    theme)
      if [[ $cword -eq 2 ]]; then
        mapfile -t COMPREPLY < <(compgen -W "default dracula nord gruvbox tokyo-night list" -- "$cur")
      fi
      ;;
    config)
      if [[ $cword -eq 2 ]]; then
        mapfile -t COMPREPLY < <(compgen -W "layout theme" -- "$cur")
      elif [[ $cword -eq 3 && "${words[2]}" == "theme" ]]; then
        mapfile -t COMPREPLY < <(compgen -W "default dracula nord gruvbox tokyo-night" -- "$cur")
      elif [[ $cword -eq 3 && "${words[2]}" == "layout" ]]; then
        local layouts=""
        if [[ -d "$home/layouts" ]]; then
          layouts=$(find "$home/layouts" -name '*.sh' -exec basename {} .sh \; 2>/dev/null)
        fi
        mapfile -t COMPREPLY < <(compgen -W "$layouts" -- "$cur")
      fi
      ;;
    *)
      # project name given — complete flags
      case "$prev" in
        --layout|-l)
          local layouts=""
          if [[ -d "$home/layouts" ]]; then
            layouts=$(find "$home/layouts" -name '*.sh' -exec basename {} .sh \; 2>/dev/null)
          fi
          mapfile -t COMPREPLY < <(compgen -W "$layouts" -- "$cur")
          ;;
        *)
          mapfile -t COMPREPLY < <(compgen -W "--layout --debug --version -f" -- "$cur")
          ;;
      esac
      ;;
  esac
}

complete -F _batipanel batipanel
complete -F _batipanel b
