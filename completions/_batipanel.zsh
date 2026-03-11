#compdef batipanel b

_batipanel_projects() {
  local home="${BATIPANEL_HOME:-$HOME/.batipanel}"
  local -a projects
  if [[ -d "$home/projects" ]]; then
    projects=(${(f)"$(find "$home/projects" -name '*.sh' -exec basename {} .sh \; 2>/dev/null)"})
  fi
  compadd -a projects
}

_batipanel_layouts() {
  local home="${BATIPANEL_HOME:-$HOME/.batipanel}"
  local -a layouts
  if [[ -d "$home/layouts" ]]; then
    layouts=(${(f)"$(find "$home/layouts" -name '*.sh' -exec basename {} .sh \; 2>/dev/null)"})
  fi
  compadd -a layouts
}

_batipanel() {
  local -a commands=(
    'new:Register a new project'
    'reload:Restart with new layout'
    'stop:Stop a session'
    'ls:List sessions and projects'
    'list:List sessions and projects'
    'layouts:Show available layouts'
    'config:Change settings'
    'theme:Change color theme'
    'help:Show help'
    'doctor:Check system health'
  )

  _arguments -C \
    '--layout[Use specific layout]: :_batipanel_layouts' \
    '-l[Use specific layout]: :_batipanel_layouts' \
    '--debug[Enable debug logging]' \
    '--version[Show version]' \
    '-v[Show version]' \
    '-f[Force (skip confirmation)]' \
    '1: :->first' \
    '*: :->rest'

  case $state in
    first)
      _describe 'command' commands
      _batipanel_projects
      ;;
    rest)
      case ${words[2]} in
        new)
          if (( CURRENT == 3 )); then
            _message 'project name'
          elif (( CURRENT == 4 )); then
            _directories
          fi
          ;;
        reload|stop)
          _batipanel_projects
          ;;
        theme)
          if (( CURRENT == 3 )); then
            compadd default dracula nord gruvbox tokyo-night list
          fi
          ;;
        config)
          if (( CURRENT == 3 )); then
            compadd layout theme
          elif (( CURRENT == 4 )) && [[ ${words[3]} == layout ]]; then
            _batipanel_layouts
          elif (( CURRENT == 4 )) && [[ ${words[3]} == theme ]]; then
            compadd default dracula nord gruvbox tokyo-night
          fi
          ;;
        *)
          _arguments \
            '--layout[Use specific layout]: :_batipanel_layouts' \
            '-l[Use specific layout]: :_batipanel_layouts'
          ;;
      esac
      ;;
  esac
}

_batipanel "$@"
