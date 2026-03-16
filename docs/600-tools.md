# Supported Tools

batipanel integrates several terminal tools into a unified workspace. Every tool has a fallback, so nothing breaks if something is missing.

## Tool Overview

| Tool | Purpose | Fallback | Install |
|------|---------|----------|---------|
| **tmux** | Session/panel manager | Required (no fallback) | Auto-installed |
| **Claude Code** | AI coding assistant | Install prompt shown | `curl -fsSL https://claude.ai/install.sh \| bash` |
| **lazygit** | Git UI | `git status` | Auto-installed |
| **btop** | System monitor | `htop` then `top` | Auto-installed |
| **yazi** | File manager | `eza --tree` then `tree` | Auto-installed |
| **eza** | Modern `ls` replacement | `tree` then `find` | Auto-installed |
| **lazydocker** | Docker UI (devops layout) | `docker ps` | Manual install |

## tmux (Required)

The backbone of batipanel. Manages sessions, windows, and panes. Version 2.6+ is required.

```bash
tmux -V    # check version
```

On distributions with old tmux (e.g., Amazon Linux 2 ships 1.8), the installer builds tmux 3.x automatically.

## Claude Code

The main panel in every layout. Claude Code is an AI coding assistant that runs in your terminal.

```bash
claude          # start Claude Code
```

If not installed, the panel shows an install prompt. Everything else still works without it.

The `remote-control` panel runs `claude remote-control`, which lets you send commands to the main Claude instance from a separate pane.

## lazygit

A full-featured terminal UI for git. Shows diffs, stages files, commits, pushes — all without leaving the terminal.

```bash
lazygit    # start lazygit
```

**Fallback**: If lazygit isn't installed, the panel runs `git status` instead.

## btop

A resource monitor that shows CPU, memory, disk, and network usage. batipanel launches it with `-p 7` (minimal preset) to fit in smaller panes.

```bash
btop       # start btop
```

**Fallback chain**: `btop` -> `htop` -> `top`. At least one of these is always available.

## yazi

A terminal file manager with preview support. Navigate your project tree, open files, move things around.

```bash
yazi       # start yazi
```

**Fallback chain**: `yazi` -> `eza --tree --level=3 --git` (auto-refreshing) -> `tree -L 3` -> `find . -maxdepth 3`

## eza

A modern replacement for `ls` with git integration, tree view, and optional icons. Used as the file tree fallback when yazi isn't available.

Icons are enabled automatically in terminals known to support them (iTerm2, WezTerm, Kitty). Force icons on with:

```bash
b config icons 1
```

## lazydocker (devops layout only)

A terminal UI for Docker. Shows containers, images, volumes, and logs.

**Fallback**: `docker ps` if lazydocker isn't installed, or a "not installed" message if Docker itself is missing.

## Checking Tool Status

```bash
b doctor
```

Shows which tools are installed, which are using fallbacks, and flags any issues. Example output:

```
  [OK]  tmux 3.4 (functional)
  [OK]  Claude Code
  [OK]  lazygit
  [OK]  btop
  [WARN]  yazi not installed (optional)
  [OK]  eza
```

## Installing Missing Tools

The batipanel installer tries to install all optional tools automatically. If something was skipped, install manually:

```bash
# macOS
brew install lazygit btop yazi eza

# Ubuntu/Debian
sudo apt install btop
# lazygit and yazi — see their GitHub repos for install instructions
```

## Next Steps

- [Layouts](300-lay.md) — see which tools appear in which layout
- [Configuration](500-cfg.md) — tool-related settings
- [FAQ](800-faq.md) — tool-specific troubleshooting

---

[Back to README](../README.md)
