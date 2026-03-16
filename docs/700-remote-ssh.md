# Remote & SSH Usage

batipanel shines on remote servers. Sessions persist across disconnects, so you never lose your workspace.

## Basic Remote Workflow

```bash
# On your server
ssh myserver
curl -fsSL https://batipanel.com/install.sh | bash
b myproject
```

That's it. You now have a full dev workspace on a remote machine.

## Detach and Reattach

The core superpower of tmux-based workspaces:

```bash
# Inside a batipanel session, detach:
Ctrl+b d

# SSH disconnects? Terminal closed? No problem.
# Just reconnect and resume:
ssh myserver
b myproject       # picks up exactly where you left off
```

All panels, running processes, and scroll history survive the disconnect.

## Managing Remote Sessions

```bash
b ls                    # list active sessions and projects
b stop myproject        # stop a session
b stop myproject -f     # stop without confirmation
b reload myproject      # restart with fresh layout
```

## Multiple Sessions

You can run multiple batipanel sessions simultaneously:

```bash
b frontend              # start frontend workspace
# Ctrl+b d to detach

b backend               # start backend workspace
# Ctrl+b d to detach

b ls                    # see both sessions
b frontend              # reattach to frontend
```

Switch between sessions inside tmux with `Ctrl+b s` (session list).

## SSH Tips

### Keep Connections Alive

Add to `~/.ssh/config` on your local machine:

```
Host *
  ServerAliveInterval 60
  ServerAliveCountdown 3
```

### Use mosh for Unstable Connections

[mosh](https://mosh.org/) handles packet loss and IP changes better than SSH:

```bash
# Install mosh on both local and remote
brew install mosh       # macOS
sudo apt install mosh   # Ubuntu

# Connect
mosh myserver
b myproject
```

### tmux Inside tmux

If you run tmux locally and connect to a remote batipanel session, you'll have nested tmux. The prefix key (`Ctrl+b`) goes to the outer (local) tmux by default.

To send the prefix to the inner (remote) tmux, press `Ctrl+b` twice:

```
Ctrl+b Ctrl+b d    # detach from inner session
Ctrl+b d           # detach from outer session
```

Alternatively, change the prefix on one of them to avoid confusion.

## Headless Server Usage

batipanel works on headless servers with no desktop environment. The only requirement is tmux 2.6+.

```bash
# Check tmux on the server
b doctor

# If tmux is too old (e.g., Amazon Linux 2)
# The installer auto-builds tmux 3.x
curl -fsSL https://batipanel.com/install.sh | bash
```

## TERM Variable Issues

If you see errors about "open terminal failed", set TERM before starting:

```bash
export TERM=xterm-256color
b myproject
```

Add it to your remote `.bashrc` to make it permanent.

## Clipboard Over SSH

To copy text from a remote batipanel session to your local clipboard:

- **iTerm2**: Enable "Allow clipboard access to terminal apps" in preferences
- **tmux copy mode**: `Ctrl+b [`, select with `v`, copy with `y`
- **WSL**: Install `xclip` (`sudo apt install xclip`)

## Next Steps

- [Getting Started](100-getting-started.md) — install on a new server
- [Usage Guide](200-usage-guide.md) — session management commands
- [FAQ](800-faq-troubleshooting.md) — connection troubleshooting

---

[Back to README](../README.md)
