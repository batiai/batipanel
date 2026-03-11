# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.3.0] - 2026-03-11

### Added
- Color theme system with 5 built-in themes (catppuccin, rose-pine, kanagawa, nord, dracula)
- iTerm2 native tmux integration (-CC mode) as opt-in with first-run prompt
- Batipanel Server: Docker-based AI Telegram bot powered by Claude (OpenClaw)
  - Interactive 3-step setup wizard (`b server init`)
  - Claude Max subscription support (no API cost)
  - Hardened Docker isolation with security defaults
- Automatic Docker/Compose installation for `b server`
- Powerline shell prompt setup (zsh agnoster + bash powerline PS1)
- Vim-style pane navigation (Alt+hjkl) and panel swapping (Alt+Shift+hjkl)
- Tmux keybindings: split (Alt+\/−), resize, zoom (Alt+f), copy mode
- Pane border labels showing tool names
- First-run setup wizard — interactive 2-step guide on first launch
- `b doctor` — comprehensive system health check
- Bash and Zsh tab completion for commands, projects, and layouts
- Debug mode — `b --debug <project>` or `BATIPANEL_DEBUG=1`
- npm/npx distribution support
- Homebrew formula with optional deps (lazygit, btop, yazi, eza)
- `make install` / `make uninstall` for Linux
- `uninstall.sh` — clean removal of config, aliases, tmux.conf entries
- Cross-platform clipboard integration (macOS pbcopy, Linux xclip, WSL clip.exe)
- WSL2 + Windows Terminal support
- GitHub Actions CI (ShellCheck + syntax + install test on Ubuntu/macOS)
- `.editorconfig` for consistent code style
- `CONTRIBUTING.md` contributor guide
- Enterprise-quality input validation and error handling

### Fixed
- Auto-fallback btop to htop on small panes
- Powerline arrow glyphs missing in bash prompt
- Auto-reload prompt on theme change
- Shell detection using `$SHELL` instead of `$BASH_VERSION`
- `size missing` errors on Linux detached tmux sessions
- Tool reinstall verification and auto-fix
- Cross-platform sed compatibility (macOS/Linux)
- Linux compatibility: eza musl fallback, PATH fix
- Single-quote injection vulnerability in generated project scripts
- `sed` injection vulnerability in `b config layout`
- `--layout` argument parsing crash under `set -euo pipefail`
- Race condition in concurrent session creation

### Changed
- Modularized lib/common.sh into 7 focused modules (core, validate, layout, session, project, doctor, wizard)
- All code comments translated to English for open-source readiness
- `NO_COLOR` / `--no-color` support (https://no-color.org)
- Config file validated with `bash -n` before sourcing
- Platform-aware install/upgrade messages
- `eza --icons` only enabled in Nerd Font-capable terminals

## [0.2.0] - 2026-02-15

### Added
- 8 layout presets: 4panel, 5panel, 6panel, 7panel, 7panel_log, 8panel, dual-claude, devops
- Multi-platform installer (macOS, Ubuntu, Fedora, Arch)
- Graceful tool fallbacks (btop → htop → top, yazi → eza → tree → find)
- iTerm2 native tmux integration (`tmux -CC`)
- Project registration and session management

### Changed
- Rebranded to batipanel with `b` alias

## [0.1.0] - 2026-01-20

### Added
- Initial release as tmux workspace manager
- Basic tmux session management
- Simple 4-panel layout
