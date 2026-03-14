#!/usr/bin/env bash
# batipanel themes-data - theme color definitions and metadata

# available themes
BATIPANEL_THEMES="default dracula nord gruvbox tokyo-night catppuccin rose-pine kanagawa"

# get all theme colors as space-separated values
# usage: _get_theme_colors <theme>
# returns: STATUS_BG STATUS_FG ACCENT ACCENT_FG WINDOW_BG WINDOW_FG
#          WINDOW_ACTIVE_BG WINDOW_ACTIVE_FG BORDER MESSAGE_BG MESSAGE_FG
#          PROMPT_USER_BG PROMPT_DIR_BG PROMPT_GIT_BG PROMPT_ERR_BG
_get_theme_colors() {
  local theme="$1"
  case "$theme" in
    default)
      echo "colour234 colour137 colour2 colour232 colour238 colour249 colour33 colour255 colour240 colour33 colour255 44 240 42 41"
      ;;
    dracula)
      echo "colour236 colour253 colour141 colour232 colour238 colour253 colour212 colour255 colour61 colour141 colour232 105 238 212 203"
      ;;
    nord)
      echo "colour236 colour253 colour110 colour232 colour238 colour253 colour67 colour255 colour240 colour67 colour255 67 238 110 131"
      ;;
    gruvbox)
      echo "colour235 colour223 colour208 colour232 colour237 colour223 colour214 colour235 colour239 colour208 colour235 172 239 142 167"
      ;;
    tokyo-night)
      echo "colour234 colour253 colour111 colour232 colour238 colour253 colour141 colour255 colour240 colour111 colour232 111 238 141 203"
      ;;
    catppuccin)
      echo "colour234 colour189 colour183 colour233 colour237 colour146 colour183 colour233 colour239 colour237 colour189 183 237 151 211"
      ;;
    rose-pine)
      echo "colour234 colour189 colour181 colour234 colour236 colour103 colour181 colour234 colour238 colour235 colour189 182 238 152 168"
      ;;
    kanagawa)
      echo "colour235 colour187 colour110 colour234 colour236 colour242 colour110 colour234 colour59 colour236 colour187 103 236 107 203"
      ;;
    *)
      return 1
      ;;
  esac
}

# theme description for display
_get_theme_desc() {
  case "$1" in
    default)     echo "Green/blue (original)" ;;
    dracula)     echo "Purple/pink dark theme" ;;
    nord)        echo "Arctic blue palette" ;;
    gruvbox)     echo "Retro warm colors" ;;
    tokyo-night) echo "Blue/purple night theme" ;;
    catppuccin)  echo "Pastel warm dark (Mocha)" ;;
    rose-pine)   echo "Soho vibes, warm rose" ;;
    kanagawa)    echo "Japanese ink painting" ;;
  esac
}

# terminal hex colors for OSC escape sequences
# returns: BG FG CURSOR USER_COLOR DIR_COLOR GIT_COLOR PROMPT_COLOR
_get_theme_terminal_colors() {
  case "$1" in
    default)     echo "#1e1e2e #cdd6f4 #f5e0dc blue cyan green magenta" ;;
    dracula)     echo "#282a36 #f8f8f2 #ff79c6 141 117 84 212" ;;
    nord)        echo "#2e3440 #d8dee9 #88c0d0 blue 110 green 67" ;;
    gruvbox)     echo "#282828 #ebdbb2 #fe8019 yellow 223 green 208" ;;
    tokyo-night) echo "#1a1b26 #c0caf5 #bb9af7 blue 111 green 141" ;;
    catppuccin)  echo "#1e1e2e #cdd6f4 #f5e0dc blue 183 green 183" ;;
    rose-pine)   echo "#191724 #e0def4 #ebbcba magenta 181 green 182" ;;
    kanagawa)    echo "#1f1f28 #dcd7ba #7e9cd8 blue 110 green 103" ;;
    *)           echo "#1e1e2e #cdd6f4 #f5e0dc blue cyan green magenta" ;;
  esac
}

# list available themes
_list_themes() {
  local current="${BATIPANEL_THEME:-default}"
  echo ""
  echo -e "  ${BLUE}Available themes:${NC}"
  echo ""
  local name desc marker
  for name in $BATIPANEL_THEMES; do
    desc=$(_get_theme_desc "$name")
    # pad name to 14 chars for alignment
    local padded
    padded=$(printf '%-14s' "$name")
    if [ "$name" = "$current" ]; then
      marker="${GREEN}*${NC}"
      echo -e "    ${marker} ${GREEN}${padded}${NC}${desc}"
    else
      echo -e "      ${padded}${desc}"
    fi
  done
  echo ""
}
