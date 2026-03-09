# Contributing to batipanel-cli

Thanks for your interest! Here's how to contribute.

## Quick Start

```bash
git clone https://github.com/batiai/batipanel-cli.git
cd batipanel
bash install.sh
```

## Making Changes

1. Fork the repo and create a branch (`git checkout -b my-feature`)
2. Make your changes
3. Run checks:
   ```bash
   # syntax check
   bash -n lib/common.sh bin/start.sh install.sh

   # shellcheck (install: brew install shellcheck / apt install shellcheck)
   shellcheck -s bash lib/common.sh bin/start.sh install.sh
   ```
4. Test the install/uninstall cycle:
   ```bash
   bash install.sh    # should work cleanly
   b doctor           # should show all green
   bash uninstall.sh  # should clean up
   ```
5. Commit and open a PR

## Code Style

- Shell scripts use **2-space indentation**
- All scripts start with `set -euo pipefail`
- Error messages use color variables (`$RED`, `$GREEN`, etc.)
- Comments and user-facing messages in **English**
- Follow existing patterns — check `lib/common.sh` for examples

## Adding a Layout

1. Copy an existing layout: `cp layouts/7panel.sh layouts/myname.sh`
2. Edit the panel splits and tool assignments
3. Add it to the `install.sh` layout copy list
4. Test on a small terminal (4panel baseline) and a large one

## Reporting Issues

Open an issue at [github.com/batiai/batipanel-cli/issues](https://github.com/batiai/batipanel-cli/issues) with:

- Your OS and terminal emulator
- `b doctor` output
- Steps to reproduce
