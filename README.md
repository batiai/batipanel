# batipanel

[![CI](https://github.com/batiai/batipanel/actions/workflows/ci.yml/badge.svg)](https://github.com/batiai/batipanel/actions)
[![npm](https://img.shields.io/npm/v/batipanel)](https://www.npmjs.com/package/batipanel)
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

> **Looking for a GUI?** [batipanel Desktop](https://batipanel.com/download) is available for macOS and Windows — same multi-panel workspace with a native app experience.

## Quick Start

```bash
# Install (pick one)
npx batipanel                                      # npm/npx
brew install batiai/tap/batipanel                   # Homebrew
curl -fsSL https://batipanel.com/install.sh | bash  # Shell script

# Run — the setup wizard guides you through everything
batipanel
```

That's it. The wizard asks 2 questions (screen size + workflow) and sets up your workspace.

---

## Installation

### npm / npx

```bash
# One-time run (no install needed)
npx batipanel

# Or install globally
npm install -g batipanel
```

### Homebrew (macOS / Linux)

```bash
brew tap batiai/tap
brew install batipanel
```

All dependencies (tmux, lazygit, btop, yazi, eza) are installed automatically.

### Shell script (Linux / WSL / macOS)

```bash
curl -fsSL https://batipanel.com/install.sh | bash
```

Or clone and install manually:

```bash
git clone https://github.com/batiai/batipanel.git
cd batipanel
bash install.sh
```

The installer auto-detects your package manager (apt, dnf, pacman, brew) and installs everything.

### Windows (WSL)

batipanel runs on Windows through WSL2 (Windows Subsystem for Linux).

**Step 1: Install WSL2** (skip if you already have it)

Open PowerShell as Administrator and run:

```powershell
wsl --install
```

Restart your computer. Ubuntu will open automatically — create a username and password.

**Step 2: Install batipanel**

Open **Windows Terminal** > **Ubuntu** tab and run:

```bash
curl -fsSL https://batipanel.com/install.sh | bash
```

**Step 3: Start**

```bash
b
```

> **Tip**: For the best experience, use [Windows Terminal](https://aka.ms/terminal) (pre-installed on Windows 11, free on Microsoft Store for Windows 10). Maximize the window or go fullscreen (F11) before launching batipanel.

### Upgrading

```bash
# npm
npm update -g batipanel

# Homebrew
brew upgrade batipanel

# Manual install — just re-run the installer
cd batipanel && git pull && bash install.sh
```

Your projects and settings are always preserved.

### Uninstalling

```bash
# npm
npm uninstall -g batipanel

# Homebrew
brew uninstall batipanel

# Manual
bash uninstall.sh
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
b doctor                           # Check system health
b help                             # Show all commands
```

### How It Works

1. `b myproject` checks if a session already exists
2. If yes -> reattaches (your work is exactly where you left it)
3. If no -> creates a new multi-panel session with your chosen layout
4. Each panel auto-launches its assigned tool
5. Missing tools gracefully fall back to alternatives (e.g., btop -> htop -> top)

---

## Batipanel Server — AI Telegram Bot

Run your own AI assistant on Telegram, powered by Claude. Docker-isolated, secure, no coding required.

```
You (Telegram)  -->  Batipanel Server (Docker)  -->  Claude AI
     chat               OpenClaw gateway              Opus 4.6
```

### Why?

- **5-minute setup** — just 3 questions (bot token, AI model, your Telegram ID)
- **No API costs** — uses Claude Max subscription ($200/mo unlimited)
- **Secure by default** — Docker isolation, sandbox, allowlist access
- **Full AI capabilities** — web search, PDF analysis, code execution, reports

### Quick Start

```bash
# 1. Setup (interactive, 3 steps)
b server init

# 2. Start
b server start

# 3. Chat with your bot on Telegram!
```

### Setup Walkthrough

```
$ b server init

=== Batipanel Server Setup ===

Step 1/3: Telegram Bot
  Create a bot via @BotFather on Telegram.
  Bot Token: 7234567890:AAF_xxxxx
  ✓ Token format valid

Step 2/3: AI Model
  Use Claude Max subscription (no API cost)? [Y/n]: Y
  ✓ Claude Max session detected (no API cost)

Step 3/3: Security
  Telegram User ID: 123456789
  ✓ Only user 123456789 can access the bot

=== Setup Complete ===
  Start the server: b server start
```

### Server Commands

```bash
b server init              # Interactive setup wizard
b server start             # Start the Docker server
b server stop              # Stop the server
b server status            # Show status + security report
b server logs [-f]         # View logs (follow with -f)
b server update            # Pull latest image & restart
b server config            # View configuration (secrets masked)
```

### Security

Batipanel Server runs with hardened defaults:

| Layer | Protection |
|-------|-----------|
| **Container** | Read-only filesystem, dropped Linux capabilities |
| **Sandbox** | Tool execution in separate containers |
| **Network** | Loopback binding only (not exposed to LAN) |
| **Access** | Telegram allowlist (only your user ID) |
| **Credentials** | File permissions 600, gateway token auto-generated |

### AI Model Options

| Option | Cost | Setup |
|--------|------|-------|
| **Claude Max** | $0 extra (included in $200/mo subscription) | Auto-detected from Claude CLI |
| **API Key** | Usage-based (~$15-75/M tokens) | Enter `sk-ant-...` key |

### What Can It Do?

Chat with your Telegram bot just like ChatGPT, but with full agent capabilities:

- **Web search** — "Find the latest AI news"
- **URL analysis** — "Summarize this article: https://..."
- **PDF analysis** — Send a PDF file for analysis
- **Code execution** — "Write a Python script that..."
- **Reports** — "Create a weekly report on..."
- **Q&A** — General knowledge, coding help, writing

### Requirements

- Docker & Docker Compose
- Telegram account
- Claude Max subscription (recommended) or Anthropic API key

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

## Keyboard Shortcuts

### Panel Navigation

| Shortcut | Action |
|----------|--------|
| **Alt + h/j/k/l** | Move between panels (vim-style) |
| **Alt + Arrow Keys** | Move between panels |
| **Alt + Space** | Toggle last panel |
| **Alt + f** | Zoom/focus current panel (toggle) |
| **Alt + 1-9** | Switch to window by number |
| **Alt + [ / ]** | Previous / next window |

### Panel Management

| Shortcut | Action |
|----------|--------|
| **Alt + \\** | Split vertically (new pane right) |
| **Alt + -** | Split horizontally (new pane below) |
| **Alt + x** | Close current panel (with confirmation) |
| **Alt + n** | New window |

### Panel Resizing

| Shortcut | Action |
|----------|--------|
| **Alt + Shift + Arrow** | Fine resize (1 unit) |
| **Prefix + Arrow** | Resize (5 units, prefix = Ctrl+B) |
| **Prefix + =** | Equalize all panel sizes |
| **Mouse drag** | Drag panel borders to resize |

### Panel Swapping

| Shortcut | Action |
|----------|--------|
| **Alt + Shift + h/j/k/l** | Swap panel in direction |

### Copy Mode (vi-style)

| Shortcut | Action |
|----------|--------|
| **Prefix + [** | Enter copy mode |
| **v** | Begin selection |
| **Ctrl + v** | Toggle rectangle selection |
| **y** | Copy to system clipboard |
| **Escape** | Exit copy mode |

### Session Management

| Shortcut | Action |
|----------|--------|
| **Prefix + s** | List sessions |
| **Prefix + S** | New session |
| **Prefix + r** | Reload tmux config |

---

## Shell Theme

The installer sets up a Powerline-style shell prompt:

- **Zsh**: Oh My Zsh + agnoster theme (hostname hidden)
- **Bash**: Powerline-style PS1 with git branch (hostname hidden)
- **Fonts**: Powerline fonts auto-installed (apt/brew/git fallback)
- **tmux**: Powerline status bar with arrow separators

Each panel shows its tool name in the border (Claude, Git, Shell, Monitor, etc.).

---

## Terminal Compatibility

batipanel works with any terminal that supports tmux:

| Platform | Supported Terminals |
|----------|---------------------|
| **macOS** | Terminal.app, iTerm2, Alacritty, Kitty, WezTerm, Warp |
| **Linux** | GNOME Terminal, Konsole, Alacritty, Kitty, WezTerm, xterm |
| **Windows** | Windows Terminal + WSL2 |

- **iTerm2**: Auto-detected — uses native tmux integration for seamless tabs
- **Clipboard**: Copy from tmux works automatically on all platforms (macOS, Linux X11, WSL)
- **True Color**: 24-bit color support enabled by default

---

## Requirements

| Tool | Required? | Notes |
|------|-----------|-------|
| **tmux** | Yes | Auto-installed by the installer |
| **Claude Code** | Recommended | Auto-installed via `curl -fsSL https://claude.ai/install.sh \| bash` |
| lazygit | Optional | Git UI — falls back to `git status` |
| btop | Optional | System monitor — falls back to htop or top |
| yazi | Optional | File manager — falls back to eza, tree, or find |
| eza | Optional | Modern `ls` — falls back to tree or find |
| Docker | Optional | Required only for `b server` (Telegram bot) |

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
curl -fsSL https://claude.ai/install.sh | bash
```

The panel will show a reminder if Claude Code is missing — everything else still works.

### WSL: clipboard not working

Install xclip:

```bash
sudo apt install xclip
```

### How do I navigate between panels?

- **Alt + h/j/k/l** — switch panels (vim-style)
- **Alt + Arrow Keys** — switch panels
- **Alt + f** — zoom/focus a panel (toggle fullscreen)
- **Prefix + Arrow Keys** — resize panels (prefix = Ctrl+B by default)
- **Mouse** — click to select a panel, drag borders to resize, scroll to view history

---

## Contributing

Contributions are welcome! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

[MIT](LICENSE) — Copyright (c) 2026 [bati.ai](https://bati.ai)

## Trademark

"batipanel" and the batipanel logo are trademarks of batiai. The MIT license grants rights to the source code only, not to the batipanel name or branding. See [TRADEMARK.md](TRADEMARK.md) for details.

## Author

Made by [bati.ai](https://bati.ai)
