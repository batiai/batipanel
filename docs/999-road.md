# Roadmap

What's coming next for batipanel. These are planned features — timelines may shift.

## In Progress

### Custom Layout Builder

Design your own panel arrangements without editing shell scripts. Specify panel types, sizes, and positions through a simple config format or interactive builder.

```bash
# Planned usage
b layout create mysetup
b layout edit mysetup
```

### Plugin System for Panel Types

Extend batipanel with custom panel types beyond the built-in tools. Write a simple shell function, drop it in a plugins directory, and use it in any layout.

```bash
# Planned: register a custom panel type
~/.batipanel/plugins/my-panel.sh
```

## Planned

### Team Shared Configurations

Share layouts, themes, and project configs across a team. Check a `.batipanel.yaml` into your repo and everyone gets the same workspace setup.

```yaml
# Planned: .batipanel.yaml in project root
layout: 7panel
theme: tokyo-night
panels:
  logs: "npm run dev"
```

### Built-in Terminal Recording (Asciinema Integration)

Record your terminal sessions for demos, documentation, or debugging. Start and stop recording from within batipanel.

```bash
# Planned usage
b record start myproject
b record stop
b record play last
```

### Web Dashboard for Remote Session Management

A lightweight web UI to view and manage your batipanel sessions from a browser. See active sessions, panel status, and reattach with one click.

### VSCode / JetBrains IDE Integration

Open a batipanel workspace from your IDE's terminal panel, or sync project registrations between batipanel and your IDE's project list.

## How to Influence the Roadmap

- Vote on existing feature requests at [github.com/batiai/batipanel/issues](https://github.com/batiai/batipanel/issues)
- Open a new issue with the `feature-request` label
- Submit a PR — see [Contributing](900-con.md)

## Recently Shipped

- 8 color themes with live reload
- Apple Terminal.app full support (auto-configured font and colors)
- Powerline glyphs enabled by default
- iTerm2 native integration (`tmux -CC` mode)
- devops layout with lazydocker
- dual-claude layout for multi-agent workflows
- `b doctor` system health check
- `b reset` for clean slate recovery
- Tab completion for bash and zsh

---

[Back to README](../README.md)
