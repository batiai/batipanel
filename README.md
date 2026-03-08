# batipanel

[![CI](https://github.com/batiai/batipanel/actions/workflows/ci.yml/badge.svg)](https://github.com/batiai/batipanel/actions)
[![Latest Release](https://img.shields.io/github/v/release/batiai/batipanel)](https://github.com/batiai/batipanel/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20WSL-lightgrey)]()

AI-powered terminal workspace manager. One command to launch a fully configured multi-panel development environment with Claude Code, git, system monitor, file browser, and more.

```
┌────────────────────────────────┬──────────────┐
│                                │ system       │
│  Claude Code (AI assistant)    │ monitor      │
│                                ├──────────────┤
│                                │ file tree    │
│                                ├──────────────┤
│                                │ remote ctrl  │
├───────────┬────────────────────┴──────────────┤
│ git       │ terminal           │ logs         │
└───────────┴────────────────────┴──────────────┘
```

## Quick Start

```bash
# 1. Install
brew install batiai/tap/batipanel   # macOS
# or
curl -fsSL https://raw.githubusercontent.com/batiai/batipanel/master/install.sh | bash   # Linux/WSL

# 2. Run — the setup wizard guides you through everything
batipanel
```

That's it. The wizard asks 2 questions (screen size + workflow) and sets up your workspace.

---

## Installation

### macOS

**Option A: Homebrew (recommended)**

```bash
brew tap batiai/tap
brew install batipanel
```

All dependencies (tmux, lazygit, btop, yazi, eza) are installed automatically.

**Option B: Manual**

```bash
git clone https://github.com/batiai/batipanel.git
cd batipanel
make install
```

After installing, add the short alias `b` for convenience:

```bash
echo "alias b='batipanel'" >> ~/.zshrc && source ~/.zshrc
```

### Linux (Ubuntu, Fedora, Arch)

```bash
git clone https://github.com/batiai/batipanel.git
cd batipanel
make install
```

Or as a one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/batiai/batipanel/master/install.sh | bash
```

The installer auto-detects your package manager (apt, dnf, pacman) and installs everything.

### Windows (WSL)

batipanel runs on Windows through WSL2 (Windows Subsystem for Linux).

**Step 1: Install WSL2** (skip if you already have it)

Open PowerShell as Administrator and run:

```powershell
wsl --install
```

Restart your computer. Ubuntu will open automatically — create a username and password.

**Step 2: Install batipanel**

Open **Windows Terminal** → **Ubuntu** tab and run:

```bash
curl -fsSL https://raw.githubusercontent.com/batiai/batipanel/master/install.sh | bash
```

**Step 3: Start**

```bash
b
```

> **Tip**: For the best experience, use [Windows Terminal](https://aka.ms/terminal) (pre-installed on Windows 11, free on Microsoft Store for Windows 10). Maximize the window or go fullscreen (F11) before launching batipanel.

### Upgrading

```bash
# Homebrew
brew upgrade batipanel

# Manual install — just re-run the installer
cd batipanel && git pull && make install
```

Your projects and settings are always preserved.

### Uninstalling

```bash
# Homebrew
brew uninstall batipanel

# Manual
make uninstall          # or: bash uninstall.sh
```

---

## Usage

### First Run

Just type `b` (or `batipanel`). The setup wizard will:

1. Ask your **screen size** (laptop / external monitor / ultrawide)
2. Ask your **workflow** (AI coding / general dev / DevOps)
3. Pick the best layout for you
4. Register your current directory as a project
5. Launch immediately

### Everyday Commands

```bash
b myproject                        # Start or resume a project
b myproject --layout 6panel        # Start with a specific layout
b new myproject ~/path/to/project  # Register a new project
b stop myproject                   # Stop a session
b ls                               # List sessions & projects
b layouts                          # Show available layouts
b config layout 7panel_log         # Change default layout
b help                             # Show all commands
```

### How It Works

1. `b myproject` checks if a session already exists
2. If yes → reattaches (your work is exactly where you left it)
3. If no → creates a new multi-panel session with your chosen layout
4. Each panel auto-launches its assigned tool
5. Missing tools gracefully fall back to alternatives (e.g., btop → htop → top)

---

## Layouts

Choose the layout that fits your screen and workflow. Change anytime with `b <project> --layout <name>`.

### 7panel (default) — Claude-focused workspace

Best for: external monitors, AI-assisted coding

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

### 4panel — Minimal workspace

Best for: laptops (13-14"), smaller screens

```
┌────────────────────────┬──────────────────┐
│                        │                  │
│  claude (main)         │  btop            │
│                        │                  │
├────────────────────────┼──────────────────┤
│  lazygit               │  terminal        │
└────────────────────────┴──────────────────┘
```

### 6panel — Balanced grid

Best for: general development on a large monitor

```
┌──────────────┬───────────────┬────────────────┐
│ remote-ctrl  │ claude        │ btop           │
├──────────────┼───────────────┼────────────────┤
│ lazygit      │ terminal      │ file tree      │
└──────────────┴───────────────┴────────────────┘
```

### dual-claude — Multi-agent workspace

Best for: ultrawide monitors, running two Claude instances

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

Best for: Docker/Kubernetes workflows

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

<details>
<summary>More layouts: 5panel, 7panel_log, 8panel</summary>

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

</details>

---

## Terminal Compatibility

batipanel works with any terminal that supports tmux:

| Platform | Supported Terminals |
|---|---|
| **macOS** | Terminal.app, iTerm2, Alacritty, Kitty, WezTerm, Warp |
| **Linux** | GNOME Terminal, Konsole, Alacritty, Kitty, WezTerm, xterm |
| **Windows** | Windows Terminal + WSL2 |

- **iTerm2**: Auto-detected — uses native tmux integration for seamless tabs
- **Clipboard**: Copy from tmux works automatically on all platforms (macOS, Linux X11, WSL)

---

## Requirements

| Tool | Required? | Notes |
|---|---|---|
| **tmux** | Yes | Auto-installed by the installer |
| **Claude Code** | Recommended | `npm i -g @anthropic-ai/claude-code` — the AI panel |
| lazygit | Optional | Git UI — falls back to `git status` |
| btop | Optional | System monitor — falls back to htop or top |
| yazi | Optional | File manager — falls back to eza, tree, or find |
| eza | Optional | Modern `ls` — falls back to tree or find |

All optional tools are auto-installed when possible. If any are missing, batipanel still works — each panel gracefully falls back to a simpler alternative.

---

## Customization

### Register a project

```bash
b new myproject ~/code/myproject
```

### Change default layout

```bash
b config layout 7panel_log
```

### Create a custom layout

```bash
cp ~/.batipanel/layouts/7panel.sh ~/.batipanel/layouts/custom.sh
# Edit custom.sh to your needs
b myproject --layout custom
```

---

## Troubleshooting

### "tmux is not installed"

The installer tries to install tmux automatically. If it fails:

```bash
# macOS
brew install tmux

# Ubuntu/Debian
sudo apt install tmux

# Fedora
sudo dnf install tmux
```

### Panels look too small or overlap

Your terminal window might be too small for the selected layout. Try:

```bash
b myproject --layout 4panel    # simpler layout for smaller screens
```

Or maximize your terminal window / go fullscreen.

### "claude CLI not installed"

Install Claude Code:

```bash
npm i -g @anthropic-ai/claude-code
```

You need [Node.js](https://nodejs.org/) first. The panel will show a reminder if Claude Code is missing — everything else still works.

### WSL: clipboard not working

Install xclip:

```bash
sudo apt install xclip
```

### How do I navigate between panels?

- **Alt + Arrow Keys** — switch between panels
- **Prefix + Arrow Keys** — resize panels (prefix = Ctrl+B by default)
- **Mouse** — click to select a panel, scroll to view history

---

## License

MIT

## Author

Made by [bati.ai](https://github.com/batiai)
