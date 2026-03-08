# Changelog

## 0.3.0 (Unreleased)

### Added
- First-run setup wizard — interactive 2-step guide on first launch
- `b doctor` — comprehensive system health check (tmux, tools, config, aliases, completion)
- Bash and Zsh tab completion for commands, projects, and layouts
- `check_tmux_version()` — OS-specific install instructions when tmux is missing
- `check_terminal_size()` — warns when terminal is too small for selected layout
- Debug mode — `b --debug <project>` or `BATIPANEL_DEBUG=1`
- `b stop` confirmation prompt — skip with `b stop <project> -f`
- `b help` command
- Version display in help output
- Homebrew formula with optional deps (lazygit, btop, yazi, eza)
- `make install` / `make uninstall` for Linux
- `uninstall.sh` — clean removal of config, aliases, tmux.conf entries
- Cross-platform clipboard integration (macOS pbcopy, Linux xclip, WSL clip.exe)
- WSL2 + Windows Terminal support
- GitHub Actions CI (ShellCheck + syntax check + install test on Ubuntu/macOS)
- `.editorconfig` for consistent code style
- `CONTRIBUTING.md` contributor guide

### Fixed
- `tmux new-session` failure now shows a clear error message instead of silent exit
- Single-quote injection vulnerability in generated project scripts (`printf '%q'`)
- `sed` injection vulnerability in `b config layout` (layout name validation)
- `--layout` argument parsing crash under `set -euo pipefail`
- Empty project list now shows helpful guidance instead of blank output

### Changed
- All code comments translated to English for open-source readiness
- `install.sh` now creates `config/` directory during setup
- Platform-aware install/upgrade messages (no more "brew install" on Linux)
- `eza --icons` only enabled in Nerd Font-capable terminals
- Shell RC detection prioritizes running shell over file existence
- Linux install.sh shows manual install links for tools not in default repos

## 0.2.0

- Rebranded to batipanel with `b` alias
- 8 layout presets: 4panel, 5panel, 6panel, 7panel, 7panel_log, 8panel, dual-claude, devops
- Multi-platform installer (macOS, Ubuntu, Fedora, Arch)
- Graceful tool fallbacks (btop → htop → top, yazi → eza → tree → find)
- iTerm2 native tmux integration (`tmux -CC`)
- Project registration and session management

## 0.1.0

- Initial release as tmux workspace manager
