# Getting Started

Everything you need to go from zero to a running workspace in under 2 minutes.

## Install

Pick whichever method suits you:

```bash
# Recommended — one-liner, auto-detects your package manager
curl -fsSL https://batipanel.com/install.sh | bash

# npm — global install
npm install -g batipanel

# npm — one-time run (no install)
npx batipanel

# Homebrew (macOS)
brew tap batiai/tap
brew install batipanel

# Manual
git clone https://github.com/batiai/batipanel.git
cd batipanel && bash install.sh
```

The installer auto-detects your package manager (apt, dnf, pacman, brew, port, nix, apk, zypper) and installs tmux, Claude Code, lazygit, btop, yazi, eza, and a Nerd Font.

## First Run

After install, just type `b` in your terminal. On first run, the setup wizard walks you through picking a layout and theme. Then:

```bash
cd ~/my-project
b myproject
```

That's it. batipanel creates a multi-panel tmux workspace with Claude Code, git UI, system monitor, file browser, and a terminal — all wired up and ready.

If the project name isn't registered yet, batipanel offers to register the current directory automatically.

## Activating the `b` Alias

The installer adds a shell alias to your `.bashrc` or `.zshrc`. If it didn't take effect, reload your shell:

```bash
source ~/.bashrc   # or source ~/.zshrc
```

Or add it manually:

```bash
echo "alias b='bash ~/.batipanel/bin/start.sh'" >> ~/.zshrc
```

## Verify Your Setup

```bash
b doctor
```

This checks tmux, Claude Code, optional tools, config, and shell alias. Green means good.

## Upgrading

```bash
# npm
npm update -g batipanel

# Homebrew
brew upgrade batipanel

# Manual
cd batipanel && git pull && bash install.sh
```

Your projects and settings are preserved during upgrades.

## Uninstalling

```bash
# npm
npm uninstall -g batipanel

# Homebrew
brew uninstall batipanel

# Manual
bash uninstall.sh
```

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| macOS | Stable | Terminal.app, iTerm2 |
| Ubuntu / Debian | Stable | GNOME Terminal |
| Amazon Linux / CentOS | Beta | tmux 2.6+ auto-installed |
| Windows | Beta | WSL2 + Windows Terminal |
| Other Linux | Community | Alacritty, Kitty, WezTerm |

## Next Steps

- [Usage Guide](200-usage-guide.md) — learn the `b` command
- [Layouts](300-layouts-panels.md) — pick the right panel arrangement
- [Themes](400-themes-appearance.md) — customize colors

---

[Back to README](../README.md)
