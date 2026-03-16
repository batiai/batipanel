#!/usr/bin/env bash
# scripts/install/fonts.sh - Linux nerd font install, macOS brew font, Apple Terminal profile setup

# === 9b. install Nerd Font + configure terminal ===

_install_nerd_font_linux() {
  local font_dir="$HOME/.local/share/fonts"
  # skip if already installed
  if ls "$font_dir"/MesloLGS* &>/dev/null 2>&1; then
    return 0
  fi
  echo "  Installing Nerd Font (MesloLGS NF) for powerline glyphs..."
  mkdir -p "$font_dir"
  local base_url="https://github.com/romkatv/powerlevel10k-media/raw/master"
  local fonts=(
    "MesloLGS NF Regular.ttf"
    "MesloLGS NF Bold.ttf"
    "MesloLGS NF Italic.ttf"
    "MesloLGS NF Bold Italic.ttf"
  )
  for f in "${fonts[@]}"; do
    local encoded="${f// /%20}"
    curl -fsSL "$base_url/$encoded" -o "$font_dir/$f" 2>/dev/null || true
  done
  # rebuild font cache
  if command -v fc-cache &>/dev/null; then
    fc-cache -f "$font_dir" 2>/dev/null || true
  fi
  echo "    Nerd Font installed to $font_dir"
}

setup_fonts_and_terminal() {
  if [ "$OS" = "Linux" ]; then
    _install_nerd_font_linux
  fi

  if [ "$OS" = "Darwin" ]; then
    echo ""

    # install Nerd Font via Homebrew
    if command -v brew &>/dev/null; then
      if ! brew list --cask font-meslo-lg-nerd-font &>/dev/null 2>&1; then
        echo "Installing Nerd Font (MesloLGS NF) for powerline glyphs..."
        brew install --cask font-meslo-lg-nerd-font 2>/dev/null || true
      fi
    fi

    # auto-configure Apple Terminal: create/update "batipanel" profile
    if [ "${TERM_PROGRAM:-}" = "Apple_Terminal" ]; then
      _bp_profile="batipanel"
      _current_profile=$(defaults read com.apple.Terminal "Default Window Settings" 2>/dev/null || echo "Basic")

      # hex to AppleScript RGB helper
      _hex_to_applescript_rgb() {
        local hex="${1#\#}"
        local r=$((16#${hex:0:2}))
        local g=$((16#${hex:2:2}))
        local b=$((16#${hex:4:2}))
        echo "$((r * 257)), $((g * 257)), $((b * 257))"
      }

      # get theme colors
      _bp_theme="${BATIPANEL_THEME:-default}"
      _bp_term_colors=""
      if declare -f _get_theme_terminal_colors &>/dev/null; then
        _bp_term_colors=$(_get_theme_terminal_colors "$_bp_theme")
      else
        _bp_term_colors="#1e1e2e #cdd6f4 #f5e0dc blue cyan green magenta"
      fi
      read -r _bp_bg _bp_fg _bp_cursor _ <<< "$_bp_term_colors"

      # create or update the batipanel profile
      _setup_bp_profile() {
        echo "  Setting up Apple Terminal profile: ${_bp_profile}..."

        # create profile by duplicating current one (inherits encoding, shell settings)
        osascript <<APPLESCRIPT 2>/dev/null || true
tell application "Terminal"
  -- duplicate current profile as base if batipanel doesn't exist yet
  if not (exists settings set "${_bp_profile}") then
    set baseProfile to settings set "${_current_profile}"
    set newProfile to make new settings set with properties {name:"${_bp_profile}"}
  end if
end tell
APPLESCRIPT

        # set Nerd Font (try v3, v2, mono variants)
        local _nf_applied=false
        for _nf_name in "MesloLGSNF-Regular" "MesloLGSNerdFont-Regular" "MesloLGS-NF-Regular"; do
          if osascript -e "tell application \"Terminal\" to set font name of settings set \"${_bp_profile}\" to \"${_nf_name}\"" 2>/dev/null; then
            _nf_applied=true
            break
          fi
        done
        if [ "$_nf_applied" = true ]; then
          # font confirmed — enable powerline glyphs
          if ! grep -qF 'BATIPANEL_ICONS' "$SHELL_RC" 2>/dev/null; then
            echo 'export BATIPANEL_ICONS="1"' >> "$SHELL_RC"
          fi
        else
          echo "    Warning: Could not set Nerd Font. Powerline glyphs may not render."
          echo "    Install manually: brew install --cask font-meslo-lg-nerd-font"
        fi
        osascript -e "tell application \"Terminal\" to set font size of settings set \"${_bp_profile}\" to 13" 2>/dev/null || true

        # apply theme colors to the batipanel profile
        if [[ "$_bp_bg" =~ ^# ]]; then
          local bg_rgb fg_rgb cursor_rgb
          bg_rgb=$(_hex_to_applescript_rgb "$_bp_bg")
          fg_rgb=$(_hex_to_applescript_rgb "$_bp_fg")
          cursor_rgb=$(_hex_to_applescript_rgb "$_bp_cursor")
          osascript <<APPLESCRIPT 2>/dev/null || true
tell application "Terminal"
  set background color of settings set "${_bp_profile}" to {${bg_rgb}}
  set normal text color of settings set "${_bp_profile}" to {${fg_rgb}}
  set cursor color of settings set "${_bp_profile}" to {${cursor_rgb}}
end tell
APPLESCRIPT
        fi

        # set as default profile for new windows
        osascript <<APPLESCRIPT 2>/dev/null || true
tell application "Terminal"
  set default settings to settings set "${_bp_profile}"
  set startup settings to settings set "${_bp_profile}"
end tell
APPLESCRIPT

        # apply to current window
        osascript <<APPLESCRIPT 2>/dev/null || true
tell application "Terminal"
  set w to front window
  set current settings of w to settings set "${_bp_profile}"
end tell
APPLESCRIPT
        echo "    Profile '${_bp_profile}' configured and set as default"
      }

      if [ "$_current_profile" = "$_bp_profile" ]; then
        # already using batipanel profile — update it silently
        _setup_bp_profile
      else
        # first install or different profile — ask user
        echo ""
        echo "  Apple Terminal detected (current profile: ${_current_profile})"
        echo "  batipanel can create a dedicated '${_bp_profile}' profile with:"
        echo "    - Nerd Font (MesloLGS) for powerline glyphs"
        echo "    - Dark theme colors"
        echo ""
        printf "  Apply batipanel Terminal profile? [Y/n] "
        _bp_answer=""
        if [ -t 0 ]; then
          read -r _bp_answer
        else
          read -r _bp_answer < /dev/tty 2>/dev/null || _bp_answer="y"
        fi
        case "$_bp_answer" in
          [nN]*)
            echo "  Skipped. You can set your font to a Nerd Font manually."
            ;;
          *)
            _setup_bp_profile
            ;;
        esac
      fi
    fi
  fi
}
