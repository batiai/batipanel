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
├──────────┬────────────┼──────────┼────────────┤
│ remote   │ terminal   │ file tree│            │
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

## Installation

### Quick install (macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/batiai/batipanel/master/install.sh | bash
```

### Manual install

```bash
git clone https://github.com/batiai/batipanel.git
cd batipanel
bash install.sh
```

## Requirements

- **tmux** (required)
- **Claude Code** CLI — `npm i -g @anthropic-ai/claude-code`
- lazygit, btop, eza (auto-installed via Homebrew)

## Usage

```bash
# Start or resume a project session
b myproject

# Start with a specific layout
b myproject --layout 7panel_log

# Register a new project
b new myproject ~/path/to/project

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

## Customization

### Add a new project

```bash
b new myproject ~/code/myproject
```

This creates `~/tmux/myproject.sh`. Edit it to customize the layout:

```bash
#!/usr/bin/env bash
SESSION="${1:-myproject}"
PROJECT=~/code/myproject
source ~/tmux/common.sh
load_layout "$SESSION" "$PROJECT" "${LAYOUT:-}"
```

### Change default layout

```bash
b config layout 7panel_log
```

### Create a custom layout

Copy an existing layout file and modify it:

```bash
cp ~/tmux/layout_7panel.sh ~/tmux/layout_custom.sh
# Edit layout_custom.sh to your needs
b myproject --layout custom
```

## iTerm2 Support

batipanel auto-detects iTerm2 and uses native tmux integration (`tmux -CC`) for a seamless experience with native tabs and split panes.

## License

MIT

## Author

Made by [bati.ai](https://github.com/batiai)
