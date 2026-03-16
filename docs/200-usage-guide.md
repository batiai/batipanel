# Usage Guide

How to use the `b` command to manage your workspaces, sessions, and projects.

## The `b` Command

`b` is the single entry point for everything. It's a shell alias that points to `~/.batipanel/bin/start.sh`.

```bash
b help              # show all commands
b --version         # show version
```

## Starting a Workspace

```bash
b myproject                        # start or resume session
b myproject --layout 6panel        # start with a specific layout
```

If a session named `myproject` already exists, `b myproject` reattaches to it instantly. No work is lost.

If the project name isn't registered, batipanel asks if you want to register the current directory and start.

## Registering Projects

```bash
b new myproject ~/path/to/project
```

This saves the project path so `b myproject` always opens in the right directory. Project configs live in `~/.batipanel/projects/`.

You can also just `cd` into a directory and run `b somename` — batipanel offers to register it on the spot.

## Session Lifecycle

```bash
b myproject          # start or resume
b stop myproject     # stop (asks for confirmation)
b stop myproject -f  # stop without confirmation
b reload myproject   # kill and restart with fresh layout
b ls                 # list active sessions + registered projects
```

### Detach and Reattach

While inside a session, press `Ctrl+b d` to detach. The session keeps running in the background. Come back anytime with `b myproject`.

This is especially useful over SSH — disconnect, reconnect, pick up where you left off.

## Configuration

```bash
b config layout 6panel       # change default layout
b config layout              # show current default
b theme dracula              # change color theme
b theme                      # list all themes
b config iterm-cc on         # enable iTerm2 native integration
```

See [Configuration](500-configuration.md) for all options.

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Alt + h/j/k/l | Move between panels (vim-style) |
| Alt + Arrow Keys | Move between panels |
| Alt + f | Zoom/focus current panel (toggle) |
| Alt + Space | Toggle last panel |
| Alt + 1-9 | Switch to window by number |
| Alt + \\ | Split vertically |
| Alt + - | Split horizontally |
| Alt + x | Close current panel |
| Alt + Shift + h/j/k/l | Swap panel in direction |
| Ctrl+b d | Detach from session |
| Ctrl+b s | List sessions |

## System Health Check

```bash
b doctor
```

Checks tmux version, optional tools, config, shell alias, tmux.conf, and tab completion. Fix any issues it flags.

## Reset Everything

```bash
b reset
```

Kills all tmux sessions, removes registered projects and config, and re-tests tmux. Use this as a last resort if something is stuck.

## Next Steps

- [Layouts](300-layouts-panels.md) — choose your panel arrangement
- [Themes](400-themes-appearance.md) — customize the look
- [Remote & SSH](700-remote-ssh.md) — use batipanel on servers

---

[Back to README](../README.md)
