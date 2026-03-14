# batipanel

[![CI](https://github.com/batiai/batipanel/actions/workflows/ci.yml/badge.svg)](https://github.com/batiai/batipanel/actions)
[![npm](https://img.shields.io/npm/v/batipanel)](https://www.npmjs.com/package/batipanel)
[![Latest Release](https://img.shields.io/github/v/release/batiai/batipanel)](https://github.com/batiai/batipanel/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20WSL-lightgrey)]()

**AI-powered terminal workspace manager.** One command to launch a fully configured, beautifully themed multi-panel development environment.

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

---

## Why batipanel?

AI 시대의 개발 환경은 달라져야 합니다. Claude Code 같은 AI 어시스턴트, Git UI, 시스템 모니터, 파일 브라우저를 **매번 하나씩 열고 배치하는 건 비효율적**입니다. batipanel은 이 모든 것을 **명령어 한 줄**로 해결합니다.

### 1. AI-First Multi-Panel Workspace

> AI 시대에 최적화된 개발환경을 명령어 한 줄로 구축

#### 1-1. AI Interface (Claude Code + Remote Control)

- **Claude Code** 패널이 워크스페이스의 중심 — 55% 이상의 화면을 차지하는 넓은 AI 작업 공간
- **Remote Control** 패널로 별도 터미널에서 Claude에 명령 전달 (다른 작업 중에도 AI 제어 가능)
- **Dual-Claude** 레이아웃으로 두 개의 Claude 인스턴스를 동시에 운영 (멀티 에이전트)

#### 1-2. Multi-Panel Development Tools

- **Git UI** (lazygit) — 시각적 Git 관리, 커밋/브랜치/머지를 한눈에
- **System Monitor** (btop) — CPU, 메모리, 네트워크 실시간 모니터링
- **File Browser** (yazi) — 트리 구조 파일 탐색, Nerd Font 아이콘 지원
- **Terminal** — 범용 쉘, 빌드/테스트 명령 실행
- **Logs** — `tail -f`, `npm run dev` 등 실시간 로그 모니터링

#### 1-3. Smart Layout System

화면 크기와 워크플로우에 맞는 **8가지 레이아웃** 제공:

| Layout | Panels | Best For |
|--------|--------|----------|
| `7panel` (default) | 7 | AI 코딩 + 외장 모니터 |
| `4panel` | 4 | 노트북 (13-14") |
| `5panel` | 5 | 균형 잡힌 워크스페이스 |
| `6panel` | 6 | 일반 개발 + 대형 모니터 |
| `7panel_log` | 7 | 풀 로그 바 + 개발 |
| `8panel` | 8 | 듀얼 Claude + 모니터링 |
| `dual-claude` | 7 | 멀티 AI 에이전트 + 울트라와이드 |
| `devops` | 5 | Docker/K8s 운영 |

각 도구가 없어도 **자동 폴백** — btop -> htop -> top, yazi -> eza -> tree -> find

### 2. Instant Session Resume

> 언제든 떠나고, 언제든 돌아오는 작업 환경

tmux 세션 기반으로 **작업 상태가 완벽히 보존**됩니다:

- `b myproject` — 세션이 있으면 즉시 복귀, 없으면 새로 생성
- AI 대화, Git 상태, 로그 출력 등 **모든 패널의 상태가 그대로** 유지
- SSH 연결이 끊겨도, 터미널을 닫아도 — 다시 `b myproject` 하면 끝
- 여러 프로젝트를 동시에 운영하고 `b ls`로 관리

```bash
b myproject          # 작업 시작 (또는 이전 세션 복귀)
# ... 작업 중 터미널 닫기, SSH 끊김 등 ...
b myproject          # 모든 패널이 그대로 — 바로 이어서 작업
```

### 3. AI Telegram Bot (OpenClaw) — One-Command Deploy

> 격리된 Docker 환경에서 개인 AI 봇을 명령어 한 줄로 배포

#### 3-1. Zero-Cost AI for Claude Max Users

- Claude Max 구독($200/mo)이 있다면 **추가 API 비용 $0**
- OpenClaw 게이트웨이가 Claude Max 세션을 활용 — 토큰 과금 없음
- API 키 방식도 지원 (유량 기반 과금)

#### 3-2. Secure by Default — Docker Isolation

보안 걱정 없는 **5계층 격리**:

| Layer | Protection |
|-------|-----------|
| **Container** | Read-only filesystem, dropped Linux capabilities |
| **Sandbox** | Tool execution in separate containers |
| **Network** | Loopback binding only (not exposed to LAN) |
| **Access** | Telegram allowlist (only your user ID) |
| **Credentials** | File permissions 600, gateway token auto-generated |

#### 3-3. 5-Minute Setup

```bash
b server init     # 3단계 대화형 설정 (봇 토큰, AI 모델, 사용자 ID)
b server start    # Docker 서버 시작 — 끝!
```

웹 검색, PDF 분석, 코드 실행, 리포트 생성 등 **풀 AI 에이전트 기능**을 Telegram으로 사용.

---

## Quick Start

```bash
# Install (pick one)
npx batipanel                                      # npm/npx
brew install batiai/tap/batipanel                   # Homebrew
curl -fsSL https://batipanel.com/install.sh | bash  # Shell script (domain)
curl -fsSL https://raw.githubusercontent.com/batiai/batipanel/master/scripts/web-install.sh | bash  # Shell script (GitHub)

# Run — the setup wizard guides you through everything
batipanel
```

That's it. The wizard asks 2 questions (screen size + workflow) and sets up your workspace.

---

## Installation

### Complete beginner? Start here

**터미널 사용이 처음이거나, npm/Homebrew가 없는 경우** 아래 순서를 따르세요:

<details>
<summary><b>macOS — 처음부터 설치하기</b></summary>

1. **Terminal 열기**: `Cmd + Space` → "Terminal" 검색 → 실행

2. **설치 명령어 실행** (복사 후 붙여넣기):
   ```bash
   git clone https://github.com/batiai/batipanel.git
   cd batipanel
   bash install.sh
   ```
   - tmux가 없으면 설치 방법을 안내합니다 (Homebrew, MacPorts, Nix 등)
   - 비밀번호를 물어보면 Mac 로그인 비밀번호 입력

3. **새 터미널 열기** 후 실행:
   ```bash
   b
   ```

> **npm/npx로 설치하고 싶다면**: 먼저 [nvm](https://github.com/nvm-sh/nvm)을 설치하세요:
> ```bash
> curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
> source ~/.zshrc
> nvm install --lts
> npx batipanel
> ```

</details>

<details>
<summary><b>Linux / WSL — 처음부터 설치하기</b></summary>

1. **터미널 열기**

2. **설치 명령어 실행**:
   ```bash
   git clone https://github.com/batiai/batipanel.git
   cd batipanel
   bash install.sh
   ```
   - 모든 도구(tmux, btop 등)가 자동 설치됩니다

3. **새 터미널 열기** 후 실행:
   ```bash
   b
   ```

> **npm/npx로 설치하고 싶다면**: 먼저 [nvm](https://github.com/nvm-sh/nvm)을 설치하세요:
> ```bash
> curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
> source ~/.bashrc
> nvm install --lts
> npx batipanel
> ```

</details>

---

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
# One-line install (no npm/Node.js required)
curl -fsSL https://raw.githubusercontent.com/batiai/batipanel/master/scripts/web-install.sh | bash
```

Or clone and install manually:

```bash
git clone https://github.com/batiai/batipanel.git
cd batipanel
bash install.sh
```

The installer auto-detects your package manager (apt, dnf, pacman, brew, port, nix, apk, zypper) and installs everything.
On macOS, any package manager works — Homebrew, MacPorts, or Nix.

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

**Wizard layout mapping:**

| Screen | AI Coding | General Dev | DevOps |
|--------|-----------|-------------|--------|
| Laptop (small) | 4panel | 4panel | devops |
| Monitor (large) | 7panel | 6panel | devops |
| Ultrawide | dual-claude | 7panel_log | devops |

### Commands

#### Session

```bash
b myproject                        # Start or resume a project
b myproject --layout 6panel        # Start with a specific layout (-l shorthand)
b stop myproject                   # Stop a session
b stop myproject -f                # Stop without confirmation
b reload myproject                 # Restart session (stop + start)
b reload myproject --layout 8panel # Restart with a different layout
```

#### Project

```bash
b new myproject ~/path/to/project  # Register a new project
b ls                               # List active sessions & registered projects
```

#### Configuration

```bash
b config layout 7panel_log         # Change default layout
b config layout                    # View current default layout
b theme                            # List available themes
b theme dracula                    # Apply a theme
b config iterm-cc on               # Enable iTerm2 native tmux integration
```

#### System

```bash
b doctor                           # Check system health
b layouts                          # Show available layouts
b help                             # Show all commands
b --version                        # Show version
```

#### Server (AI Telegram Bot)

```bash
b server init                      # Interactive setup wizard
b server start                     # Start the Docker server
b server stop                      # Stop the server
b server status                    # Show status + security report
b server logs [-f]                 # View logs (follow with -f)
b server update                    # Pull latest image & restart
b server config                    # View configuration (secrets masked)
```

#### Global Flags

| Flag | Description |
|------|-------------|
| `--version`, `-v` | Show version |
| `--debug` | Enable debug logging |
| `--no-color` | Disable colored output (respects [NO_COLOR](https://no-color.org) standard) |

### How It Works

1. `b myproject` checks if a session already exists
2. If yes -> reattaches (your work is exactly where you left it)
3. If no -> creates a new multi-panel session with your chosen layout
4. Each panel auto-launches its assigned tool
5. Missing tools gracefully fall back to alternatives (e.g., btop -> htop -> top)

---

## Color Themes

batipanel includes **8 built-in color themes** that style the tmux status bar, window tabs, pane borders, and shell prompt.

```bash
b theme              # List all themes
b theme dracula      # Apply a theme (live reload)
```

| Theme | Style |
|-------|-------|
| `default` | Green/blue — clean and balanced |
| `dracula` | Purple/pink dark theme |
| `nord` | Arctic blue palette |
| `gruvbox` | Retro warm colors |
| `tokyo-night` | Blue/purple night theme |
| `catppuccin` | Pastel warm dark (Mocha variant) |
| `rose-pine` | Warm rose, soho vibes |
| `kanagawa` | Japanese ink painting palette |

**Theme applies to:**
- tmux status bar with Powerline-style arrow separators
- Window tabs (active/inactive distinction)
- Pane borders and titles (each panel labeled: Claude, Git, Shell, Monitor, etc.)
- Shell prompt (Powerline-style segments: user, directory, git branch)
- Messages and notifications

Themes persist across sessions. Live-reload if tmux is already running.

### Shell Prompt

The installer sets up a Powerline-style shell prompt themed to match:

- **Zsh**: Oh My Zsh + agnoster theme (hostname hidden)
- **Bash**: Powerline-style PS1 with git branch (hostname hidden)
- **Fonts**: Powerline / Nerd Fonts auto-installed (apt/brew/git fallback)

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

## Customization

### Register a project

```bash
b new myproject ~/code/myproject
```

### Change default layout

```bash
b config layout 7panel_log
```

### Change color theme

```bash
b theme dracula
```

### Enable Nerd Font icons in file tree

```bash
b config icons on
```

Icons are auto-detected on known Nerd Font terminals (iTerm2, WezTerm, Kitty).

### iTerm2 native integration

```bash
b config iterm-cc on     # Use iTerm2 native splits (auto-detected on first run)
b config iterm-cc off    # Use standard tmux UI
```

### Create a custom layout

```bash
cp ~/.batipanel/layouts/7panel.sh ~/.batipanel/layouts/custom.sh
# Edit custom.sh to your needs
b myproject --layout custom
```

---

## Terminal Compatibility

batipanel works with any terminal that supports tmux:

| Platform | Supported Terminals |
|----------|---------------------|
| **macOS** | Terminal.app, iTerm2, Alacritty, Kitty, WezTerm, Warp |
| **Linux** | GNOME Terminal, Konsole, Alacritty, Kitty, WezTerm, xterm |
| **Windows** | Windows Terminal + WSL2 |

- **iTerm2**: Auto-detected — supports native tmux integration for seamless tabs
- **Clipboard**: Copy from tmux works automatically on all platforms (macOS, Linux X11, WSL)
- **True Color**: 24-bit color support enabled by default

---

## Requirements

| Tool | Required? | Notes |
|------|-----------|-------|
| **tmux** | Yes | Auto-installed by the installer |
| **Claude Code** | Recommended | AI assistant — `curl -fsSL https://claude.ai/install.sh \| bash` |
| lazygit | Optional | Git UI — falls back to `git status` |
| btop | Optional | System monitor — falls back to htop or top |
| yazi | Optional | File manager — falls back to eza, tree, or find |
| eza | Optional | Modern `ls` — falls back to tree or find |
| Docker | Optional | Required only for `b server` (Telegram bot) |

All optional tools are auto-installed when possible. If any are missing, batipanel still works — each panel gracefully falls back to a simpler alternative.

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

---

<p align="center">
  <sub>Sponsored by <a href="https://bati.ai">bati.ai</a></sub>
</p>
