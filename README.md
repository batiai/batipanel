# batipanel

AI-powered terminal workspace manager. One command to launch a fully configured multi-panel session with Claude Code, lazygit, system monitor, file tree, and more.

## Why batipanel?

Modern AI-assisted development needs more than just a terminal. You need Claude Code for AI pair programming, lazygit for version control, a system monitor, file tree, log viewer — all visible at once. **batipanel sets all of this up in one command.**

## Layouts

### 7panel (default) — Claude-focused workspace

```
┌────────────────────────────────┬──────────────┐
│                                │ btop         │
│  claude (main workspace)       ├──────────────┤
│  55% width, 70% height        │ file tree    │
│                                ├──────────────┤
│                                │ remote-ctrl  │
├───────────┬────────────────────┴──────────────┤
│ lazygit   │ terminal         │ logs/server    │
└───────────┴──────────────────┴────────────────┘
```

### 7panel_log — Full-width log bar

```
┌───────────────────────┬──────────┬────────────┐
│  claude (main)        │ lazygit  │ btop       │
├──────────┬────────────┤          │            │
│ remote   │ terminal   ├──────────┤            │
│          │            │ file tree│            │
├──────────┴────────────┴──────────┴────────────┤
│  logs — full width (tail -f / npm run dev)    │
└───────────────────────────────────────────────┘
```

### 6panel — Classic balanced grid

```
┌──────────────┬───────────────┬────────────────┐
│ remote-ctrl  │ claude        │ btop           │
├──────────────┼───────────────┼────────────────┤
│ lazygit      │ terminal      │ file tree      │
└──────────────┴───────────────┴────────────────┘
```

### 5panel — Balanced workspace

```
┌──────────────────────────────┬──────────────┐
│                              │              │
│  claude (main)               │  lazygit     │
│                              │              │
├──────────────┬───────────────┼──────────────┤
│ remote-ctrl  │  terminal     │  file tree   │
└──────────────┴───────────────┴──────────────┘
```

### 4panel — Minimal workspace

```
┌────────────────────────┬──────────────────┐
│                        │                  │
│  claude (main)         │  btop            │
│                        │                  │
├────────────────────────┼──────────────────┤
│  lazygit               │  terminal        │
└────────────────────────┴──────────────────┘
```

### 8panel — Dual Claude + monitor

```
┌──────────────┬──────────────┬──────────────┐
│              │              │              │
│  claude #1   │  claude #2   │  btop        │
│  (main)      │  (secondary) │              │
│              │              ├──────────────┤
│              │              │  logs        │
├──────────────┴──────────────┼──────────────┤
│  lazygit                    │  file mgr    │
└─────────────────────────────┴──────────────┘
```

### dual-claude — Multi-agent workspace

```
┌──────────────────┬──────────────────┐
│                  │                  │
│  claude #1       │  claude #2       │
│  (main)          │  (secondary)     │
│                  │                  │
├──────────┬───────┴──────┬───────────┤
│ lazygit  │  terminal    │ file mgr  │
└──────────┴──────────────┴───────────┘
```

### devops — Infrastructure monitoring

```
┌──────────────────┬──────────────────┐
│                  │                  │
│  claude          │  btop            │
│                  │                  │
├──────────────────┼──────────────────┤
│  lazydocker      │  terminal        │
├──────────────────┴──────────────────┤
│  logs — full width (docker logs)    │
└─────────────────────────────────────┘
```

## Requirements

- **tmux** (required — the only hard dependency)
- **Claude Code** CLI — `npm i -g @anthropic-ai/claude-code`
- lazygit, btop, yazi, eza (optional — auto-installed if possible, graceful fallback if missing)

All optional tools degrade gracefully: btop → htop → top, yazi → eza → tree → find, lazygit → git status.

## Installation

### macOS

```bash
# Quick install (Homebrew auto-detected)
curl -fsSL https://raw.githubusercontent.com/batiai/batipanel/master/install.sh | bash
```

Or manually:

```bash
git clone https://github.com/batiai/batipanel.git
cd batipanel
bash install.sh
```

### Linux (Ubuntu/Debian, Fedora, Arch)

```bash
git clone https://github.com/batiai/batipanel.git
cd batipanel
bash install.sh
```

The installer auto-detects your package manager (apt, dnf, pacman) and installs tmux + optional tools.

### Manual tmux install (if the installer can't find a package manager)

```bash
# Ubuntu/Debian
sudo apt install tmux

# Fedora
sudo dnf install tmux

# Arch
sudo pacman -S tmux

# macOS
brew install tmux
```

Then re-run `bash install.sh`.

## Project structure

```
batipanel/              # source repo
├── bin/
│   └── start.sh        # entry point
├── lib/
│   └── common.sh       # core functions & layout helpers
├── layouts/
│   ├── 4panel.sh
│   ├── 5panel.sh
│   ├── 6panel.sh
│   ├── 7panel.sh       # default
│   ├── 7panel_log.sh
│   ├── 8panel.sh
│   ├── dual-claude.sh
│   └── devops.sh
├── config/
│   └── tmux.conf
├── examples/
│   └── project.sh
└── install.sh

~/.batipanel/           # installed location
├── bin/
├── lib/
├── layouts/
├── config/
│   └── tmux.conf       # batipanel tmux config
├── projects/           # your project configs (created with `b new`)
└── config.sh           # runtime settings
```

## Usage

```bash
# Start or resume a project session
b myproject

# Start with a specific layout
b myproject --layout 7panel_log

# Register a new project
b new myproject ~/path/to/project

# Restart with a different layout
b reload myproject --layout 6panel

# Stop a session
b stop myproject

# List sessions and projects
b ls

# See available layouts
b layouts

# Change default layout
b config layout 7panel_log
```

## How it works

1. `b myproject` checks if a tmux session exists
2. If yes → reattaches to the existing session
3. If no → creates a new session with your chosen layout
4. Each panel auto-launches its assigned tool (Claude, lazygit, btop, etc.)
5. Missing tools gracefully fall back to alternatives (btop → htop → top)

## Terminal compatibility

batipanel works with any terminal that supports tmux:

- **macOS**: Terminal.app, iTerm2, Alacritty, Kitty, WezTerm, Warp
- **Linux**: GNOME Terminal, Konsole, Alacritty, Kitty, WezTerm, xterm, st
- **iTerm2**: Auto-detected — uses native tmux integration (`tmux -CC`) for seamless tabs and panes

## Customization

### Add a new project

```bash
b new myproject ~/code/myproject
```

This creates `~/.batipanel/projects/myproject.sh`.

### Change default layout

```bash
b config layout 7panel_log
```

### Create a custom layout

Copy an existing layout and modify it:

```bash
cp ~/.batipanel/layouts/7panel.sh ~/.batipanel/layouts/custom.sh
# Edit custom.sh to your needs
b myproject --layout custom
```

## License

MIT

## Author

Made by [bati.ai](https://github.com/batiai)
