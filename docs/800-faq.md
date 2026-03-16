# FAQ & Troubleshooting

Common questions and fixes for batipanel issues.

## Quick Diagnostic

Always start here:

```bash
b doctor
```

This checks everything — tmux, tools, config, aliases. Fix what it flags.

## Installation Issues

### "command not found: b"

The shell alias wasn't loaded. Reload your shell:

```bash
source ~/.bashrc    # or source ~/.zshrc
```

Or add the alias manually:

```bash
echo "alias b='bash ~/.batipanel/bin/start.sh'" >> ~/.zshrc
source ~/.zshrc
```

### "tmux is not installed"

Install with `brew install tmux` (macOS), `sudo apt install tmux` (Ubuntu), or `sudo yum install tmux` (CentOS). The installer usually handles this. If tmux is too old (need 2.6+), re-run the installer — it builds 3.x on old distros.

### "claude CLI not installed"

Claude Code is recommended but optional. Install with `curl -fsSL https://claude.ai/install.sh | bash`. Everything else works without it.

## Display Issues

### Powerline arrows show as ">" or "?"

Your terminal font isn't a Nerd Font. Fix:

- **macOS Terminal.app**: Re-run `bash install.sh` — it configures the font automatically
- **iTerm2**: Preferences > Profiles > Text > Font > select "MesloLGS NF"
- **Linux**: Set your terminal font to "MesloLGS NF" or "MesloLGS Nerd Font" in preferences
- **Windows Terminal**: Settings > Profiles > Appearance > Font face > "MesloLGS NF"

### Panels look too small

Use a simpler layout or maximize your terminal:

```bash
b myproject --layout 4panel    # fewer panels, more space each
```

Recommended minimum terminal sizes:
- `4panel`: 120x30
- `7panel`: 180x50
- `8panel`: 200x60

### Colors look wrong

Check your terminal's color support. For best results, use a terminal with true color (24-bit) support: iTerm2, GNOME Terminal, Windows Terminal, Alacritty, Kitty, WezTerm.

macOS Terminal.app supports 256 colors — themes work but with slightly less color depth.

## Session Issues

### "Failed to create tmux session"

Try these in order:

```bash
# 1. Set TERM
export TERM=xterm-256color
b myproject

# 2. Clean stale sockets
b reset

# 3. Test tmux directly
tmux new-session -d -s test && tmux kill-session -t test
```

### Session won't attach after SSH reconnect

```bash
b ls                    # check if session exists
b myproject             # try reattaching
```

If the session is gone, just start a new one. If tmux is hung:

```bash
b reset                 # nuclear option: kills everything
b myproject             # start fresh
```

### "server exited unexpectedly"

Stale tmux socket. batipanel auto-retries, but if it persists:

```bash
rm -rf /tmp/tmux-$(id -u)/
b myproject
```

## Platform-Specific

### macOS: Terminal.app profile

The installer creates a dedicated "batipanel" Terminal profile. Your original profile is untouched. If colors look off, switch to the batipanel profile manually (Terminal > Preferences > Profiles).

### WSL: Clipboard not working

```bash
sudo apt install xclip
```

### WSL: Best experience

Use [Windows Terminal](https://aka.ms/terminal) and go fullscreen (F11). The default WSL terminal has limited color and font support.

### Amazon Linux / CentOS: Old tmux

The installer auto-builds tmux 3.x. If it failed, re-run `bash install.sh` or build from source (see [tmux wiki](https://github.com/tmux/tmux/wiki/Installing)).

## Still Stuck?

1. Run `b doctor` and check the output
2. Try `b reset` followed by `b myproject`
3. Try `b myproject --debug` for verbose logging
4. Open an issue at [github.com/batiai/batipanel/issues](https://github.com/batiai/batipanel/issues) with:
   - Your OS and terminal
   - `b doctor` output
   - Steps to reproduce

---

[Back to README](../README.md)
