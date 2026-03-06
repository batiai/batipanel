# tpane

AI-powered terminal workspace for developers. One command to launch a fully configured tmux session with Claude Code, lazygit, system monitor, file tree, and more.

## Why tpane?

Modern AI-assisted development needs more than just a terminal. You need Claude Code for AI pair programming, lazygit for version control, a system monitor, file tree, log viewer — all visible at once. **tpane sets all of this up in one command.**

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
curl -fsSL https://raw.githubusercontent.com/batiai/tpane/master/install.sh | bash
```

### Manual install

```bash
git clone https://github.com/batiai/tpane.git
cd tpane
bash install.sh
```

## Requirements

- **tmux** (required)
- **Claude Code** CLI — `npm i -g @anthropic-ai/claude-code`
- lazygit, btop, eza (auto-installed via Homebrew)

## Usage

```bash
# Start or resume a project session
t myproject

# Start with a specific layout
t myproject --layout 7panel_log

# Register a new project
t new myproject ~/path/to/project

# Stop a session
t stop myproject

# List sessions and projects
t ls

# See available layouts
t layouts

# Change default layout
t config layout 7panel_log
```

## How it works

1. `t myproject` checks if a tmux session exists
2. If yes → reattaches to the existing session
3. If no → creates a new session with your chosen layout
4. Each pane auto-launches its assigned tool (Claude, lazygit, btop, etc.)
5. Missing tools gracefully fall back to alternatives (btop → htop → top)

## Customization

### Add a new project

```bash
t new myproject ~/code/myproject
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
t config layout 7panel_log
```

### Create a custom layout

Copy an existing layout file and modify it:

```bash
cp ~/tmux/layout_7panel.sh ~/tmux/layout_custom.sh
# Edit layout_custom.sh to your needs
t myproject --layout custom
```

## iTerm2 Support

tpane auto-detects iTerm2 and uses native tmux integration (`tmux -CC`) for a seamless experience with native tabs and split panes.

## License

MIT

## Author

Made by [@batiai](https://github.com/batiai)
