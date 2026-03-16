# Roadmap

Where batipanel is headed — and why.

---

## The Vision

AI is evolving fast. New tools appear every week. But setting them up, configuring them, and making them work together is still painfully manual.

**batipanel's goal: make powerful tools instantly accessible.** One command to install, one command to use. No config files, no dependency hell, no "read the docs for 30 minutes before you can start."

We believe the developer who ships fastest is the one with the best tools — and the best tools are useless if they're hard to set up.

---

## Where We Are Now

### Phase 1: AI Dev Workspace (Current)

One command installs a complete development environment:

| What | How |
|------|-----|
| **AI coding assistant** | Claude Code — auto-installed, dedicated panel |
| **Git UI** | lazygit — visual staging, branching, diffs |
| **System monitor** | btop — CPU, memory, processes at a glance |
| **File browser** | yazi — terminal file manager with preview |
| **Directory listing** | eza — modern `ls` with icons and git status |
| **Session management** | tmux — persistent sessions, survive SSH drops |
| **Terminal theming** | 8 themes, Nerd Font, powerline prompt |

```bash
curl -fsSL batipanel.com/install.sh | bash
b myproject  # everything launches
```

### Phase 2: AI Service Wrapping (In Progress)

Making AI-powered services as easy to deploy as `npm install`:

- **OpenClaw** (Telegram AI bot) — `b server init && b server start`
- Docker-based isolation with 5-layer security
- Zero-config for Claude Max subscribers

---

## What's Next

### Phase 3: One-Command Tool Ecosystem

The same "one command" philosophy, applied to the tools that teams actually use in production. Think of it like a **factory pattern for DevOps** — a modular system where each tool is a standardized module that plugs into the same interface.

```bash
# Planned — not yet available
b add grafana        # monitoring dashboards
b add n8n            # workflow automation
b add redash         # SQL dashboards & analytics
b add metabase       # business intelligence
b add ghost          # blog / CMS
b add plausible      # privacy-friendly analytics
b add uptime-kuma    # uptime monitoring
b add nocodb         # Airtable alternative
b add appsmith       # internal tool builder
b add langfuse       # LLM observability
```

Each tool:
- Installs via Docker with sane defaults
- Gets its own managed lifecycle (`b start grafana`, `b stop grafana`)
- Comes pre-wired with AI integration where applicable
- Shares a unified config and networking layer

### Phase 4: AI Fusion

As AI capabilities grow, batipanel bridges the gap between AI and every tool in your stack:

- **AI-assisted monitoring** — Claude analyzes Grafana alerts and suggests fixes
- **AI-powered queries** — ask questions in natural language, get SQL via Redash
- **AI workflow builder** — describe a workflow, n8n builds it
- **AI deployment** — describe your infra, batipanel provisions it

The end goal: **AI that doesn't just code — it operates your entire toolchain.**

---

## Near-Term Features

| Feature | Status |
|---------|--------|
| Custom layout builder (drag & drop panels) | Planned |
| Plugin system for panel types | Planned |
| Team shared configs (`.batipanel.yaml` in repo) | Planned |
| Terminal session recording (asciinema) | Planned |
| Web dashboard for remote session management | Planned |
| VSCode / JetBrains IDE integration | Exploring |

---

## Recently Shipped

- Apple Terminal.app full support (auto font, profile, colors)
- 8 color themes with live reload
- Powerline glyphs enabled by default
- iTerm2 native integration (`tmux -CC` mode)
- Amazon Linux / CentOS support (auto tmux source build)
- Auto swap setup for low-memory servers
- `b doctor` system health check
- Tab completion for bash and zsh
- Modular installer (6 modules, cross-platform)

---

## Shape the Roadmap

- Vote on features: [github.com/batiai/batipanel/issues](https://github.com/batiai/batipanel/issues)
- Open a feature request with the `feature-request` label
- Submit a PR — see [Contributing](900-contributing.md)

---

[Back to README](../README.md)
