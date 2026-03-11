# Open Source Launch Guide

Complete guide for launching batipanel as a public open-source project.

---

## Phase 1: Pre-Launch Preparation

### 1.1 Sensitive Data Audit

Before making the repo public, verify no secrets exist in the codebase or git history:

```bash
# Scan current files for hardcoded secrets
grep -rn 'sk-ant-\|AKIA\|password=' --include='*.sh' .

# Scan git history for leaked secrets
git log --all -p | grep -iE 'sk-ant-|AKIA[A-Z0-9]{16}' | head -20

# Check .gitignore covers sensitive files
cat .gitignore | grep -E '\.env|secret|credentials'
```

**If secrets are found in history**, squash or use BFG Repo-Cleaner:

```bash
# Option A: Squash all history into one commit
git checkout --orphan clean
git add -A
git commit -m "Initial release v0.3.0"
git branch -M clean master
git push origin master --force

# Option B: BFG Repo-Cleaner (removes specific files/strings)
bfg --delete-files '*.env' --replace-text passwords.txt
git reflog expire --expire=now --all && git gc --prune=now --aggressive
```

### 1.2 Trademark Protection

MIT license covers **code only**, not the brand. Add these files:

**TRADEMARK.md** — brand usage guidelines (see file in repo root)

**README.md footer** — short trademark notice:
```markdown
## Trademark
"batipanel" and the batipanel logo are trademarks of batiai.
The MIT license grants rights to the code, not the batipanel name or branding.
```

**Optional but recommended:**
- Register trademark at KIPRIS (Korea) or USPTO (US)
- Cost: ~$200-400 per class per jurisdiction
- Projects like Docker, Kubernetes, Rust all do this

### 1.3 CHANGELOG

Create `CHANGELOG.md` following [Keep a Changelog](https://keepachangelog.com/) format.
Document all notable changes per version for transparency.

---

## Phase 2: Distribution Channels

### 2.1 npm / npx

**Setup (one-time):**
```bash
npm login
```

**Publish:**
```bash
# Ensure VERSION and package.json match
npm publish --access public
```

**Users install via:**
```bash
npx batipanel              # Run without installing
npm install -g batipanel   # Global install
```

**How it works:**
1. npm downloads files listed in `package.json > files`
2. `postinstall` hook runs `bash install.sh`
3. `bin/cli.sh` is linked to PATH as `batipanel`

### 2.2 Homebrew

**Step 1: Create tap repository**
- Create `batiai/homebrew-tap` public repo on GitHub
- Add `Formula/batipanel.rb` (already exists in this repo)

**Step 2: Publish**
```bash
# Create release tag
git tag v0.3.0
git push origin v0.3.0

# Get sha256
curl -sL https://github.com/batiai/batipanel/archive/refs/tags/v0.3.0.tar.gz | shasum -a 256

# Update Formula with url + sha256, push to tap repo
```

**Users install via:**
```bash
brew tap batiai/tap
brew install batipanel
```

**Later (when popular enough):** Submit to homebrew-core for `brew install batipanel` without tap.

### 2.3 Shell Script (curl)

Configure `batipanel.com/install.sh` to redirect to GitHub raw URL:

```
https://batipanel.com/install.sh
  → 302 → https://raw.githubusercontent.com/batiai/batipanel/master/install.sh
```

Options: Cloudflare redirect rule, Vercel rewrite, nginx location block, or static bootstrap script.

### 2.4 GitHub Releases

Automate with CI. On tag push, create a release with notes:

```yaml
# .github/workflows/release.yml
on:
  push:
    tags: ['v*']
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: softprops/action-gh-release@v2
        with:
          generate_release_notes: true
```

---

## Phase 3: Go Public

### 3.1 GitHub Repository Settings

1. **Settings > General > Repository name**: Confirm `batipanel`
2. **Topics**: `tmux`, `claude`, `ai`, `terminal`, `workspace`, `developer-tools`, `cli`
3. **Description**: "AI-powered terminal workspace manager"
4. **Website**: `https://batipanel.com`
5. **Enable**: Issues, Discussions
6. **Disable**: Wiki, Projects (enable later if needed)

### 3.2 Make Public

```
Settings > General > Danger Zone > Change repository visibility > Make public
```

### 3.3 Branch Protection (after public)

```
Settings > Branches > Add rule > master
  ✓ Require pull request reviews
  ✓ Require status checks to pass (CI)
  ✓ Require branches to be up to date
```

---

## Phase 4: Promotion & User Acquisition

### Day 1 — Launch

| Channel | Action |
|---------|--------|
| **Hacker News** | "Show HN: batipanel – AI terminal workspace manager (tmux + Claude Code)" |
| **Reddit** | Post to r/commandline, r/tmux, r/terminal, r/ClaudeAI |
| **Twitter/X** | Demo GIF + tweet with #opensource #cli #tmux tags |
| **Product Hunt** | Launch page in Developer Tools category |

### Week 1-2 — Content

| Channel | Action |
|---------|--------|
| **Dev.to / Hashnode** | "How I built an AI terminal workspace manager" blog post |
| **YouTube** | 2-3 min demo video (install → run → work) |
| **GitHub Topics** | Add relevant topics to repo |

### Ongoing — Community Building

- **Awesome lists**: PR to awesome-tmux, awesome-cli-apps, awesome-claude
- **GitHub Discussions**: Enable for Q&A and feature requests
- **Discord/Slack**: Create community channel when user base grows
- **Claude Code community**: Share in relevant forums and channels

### Effective Branding Tips

1. **Demo GIF is king** — Use [asciinema](https://asciinema.org) or [vhs](https://github.com/charmbracelet/vhs) for terminal recording at README top
2. **One-line pitch** — "AI-powered terminal workspace manager"
3. **One-command install** — `npx batipanel` is a strong selling point
4. **Before/After** — Show manual tmux setup vs batipanel side by side
5. **Social proof** — Star count badge, user testimonials, community size

---

## Release Checklist (for each new version)

```
1. Update VERSION file
2. Update package.json version
3. git commit -m "chore: bump version to X.Y.Z"
4. git tag vX.Y.Z
5. git push && git push --tags
6. gh release create vX.Y.Z --generate-notes
7. npm publish --access public
8. Update homebrew-tap Formula (url + sha256)
9. Push homebrew-tap changes
```

### Version Sync Points

| Location | File | Field |
|----------|------|-------|
| Source | `VERSION` | File content |
| npm | `package.json` | `"version"` |
| Homebrew | `Formula/batipanel.rb` | `url` tag + `sha256` |
| Git | tag | `vX.Y.Z` |

All four must always match.

---

## FAQ

**Q: Does GitHub automatically promote public repos?**
A: No. GitHub Explore and Trending are based on star velocity and activity. You need to actively promote to get initial traction. Once stars accumulate, GitHub algorithms help with discoverability.

**Q: When should I submit to homebrew-core?**
A: When the project has meaningful adoption (100+ stars, active users). homebrew-core reviewers check for popularity and maintenance activity.

**Q: Should I register a trademark?**
A: Recommended if you plan to build a brand around batipanel. MIT license does not protect the name. A TRADEMARK.md file provides soft protection; formal registration provides legal protection.

**Q: How do I handle contributions from strangers?**
A: CONTRIBUTING.md is already set up. Consider adding a CLA (Contributor License Agreement) if you want to retain relicensing rights, but for most projects the DCO (Developer Certificate of Origin) is sufficient.
