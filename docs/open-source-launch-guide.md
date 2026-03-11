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

### Launch Timeline

```
Day 0   : GitHub repo → Public 전환
Day 1   : Hacker News "Show HN" 포스트        ← 가장 임팩트 큼
Day 2-3 : Reddit (r/commandline, r/tmux)
Day 3-5 : Twitter/X 데모 GIF 트윗
Week 2  : Dev.to / Hashnode 블로그 포스트
Week 2-3: awesome-lists PR 제출
Month 2+: Product Hunt 런칭 (star가 좀 쌓인 후)
```

### Day 0 — Public 전환 직후

- [ ] GitHub Discussions 활성화 (Settings > General > Features)
- [ ] Repository topics 확인: `tmux`, `claude`, `ai`, `terminal`, `workspace`, `developer-tools`, `cli`, `claude-code`, `tmux-manager`, `terminal-multiplexer`, `bash`
- [ ] Description: "AI-powered terminal workspace manager (tmux + Claude Code)"
- [ ] Homepage URL: `https://batipanel.com`
- [ ] 데모 GIF 녹화 (asciinema 또는 vhs) → README 상단에 추가

### Day 1 — Hacker News

**가장 효과적인 채널.** 첫 페이지 노출 시 하루 100-500+ stars 가능.

- **제목**: `Show HN: batipanel – One command to launch a multi-panel AI dev workspace (tmux + Claude)`
- **URL**: `https://github.com/batiai/batipanel`
- **첫 댓글** (필수): 본인 소개 + 왜 만들었는지 + 핵심 기능 3줄 요약

```
Hi, I'm the author. I built batipanel because setting up tmux for AI-assisted
coding was too tedious. One command gives you Claude Code + git + monitoring
+ file browser in a clean multi-panel layout. Works on macOS, Linux, and WSL.

Try it: npx batipanel
```

**타이밍**: 미국 동부시간 오전 8-10시 (한국시간 밤 10시-자정)가 가장 좋음.

### Day 2-3 — Reddit

각 서브레딧에 맞게 톤을 다르게:

| Subreddit | 포커스 |
|-----------|--------|
| **r/commandline** (300K+) | "I built a CLI that sets up a full dev workspace with one command" |
| **r/tmux** (30K+) | tmux 설정의 pain point 해결에 초점 |
| **r/ClaudeAI** (100K+) | Claude Code와의 통합, AI 워크플로우 |
| **r/terminal** | 터미널 UI/UX, 스크린샷/GIF 중심 |
| **r/linux** | 리눅스 호환성, WSL 지원 |
| **r/webdev**, **r/programming** | 개발 생산성 도구 관점 |

**주의**: 서브레딧마다 1-2일 간격으로 나눠서 포스트 (동시 포스팅은 스팸으로 인식됨).

### Day 3-5 — Twitter/X

- 데모 GIF (15-30초) 필수 — 텍스트만 있으면 묻힘
- 해시태그: `#opensource #cli #tmux #ClaudeCode #devtools`
- 개발자 인플루언서 멘션/태그 (tmux, CLI 관련 활동하는 사람들)
- 스레드 형식 추천:
  1. 데모 GIF + 원라이너 소개
  2. 왜 만들었나 (pain point)
  3. 핵심 기능 3가지
  4. 설치 방법 (`npx batipanel`)
  5. GitHub 링크 + star 부탁

### Week 2 — 블로그 포스트

**Dev.to / Hashnode** 중 하나 (또는 둘 다):

추천 제목들:
- "How I built a tmux workspace manager with Claude Code"
- "One command to replace your entire tmux config"
- "AI-powered terminal: my open-source dev setup"

구조:
1. Before/After 스크린샷
2. 왜 만들었나 (문제 정의)
3. 데모 (GIF/영상)
4. 기술 스택 설명
5. 설치 + 시작 방법
6. GitHub 링크

### Week 2-3 — Awesome Lists PR

이것들은 지속적 유입 채널이 됨:

- [ ] [awesome-tmux](https://github.com/rothgar/awesome-tmux) — PR 제출
- [ ] [awesome-cli-apps](https://github.com/agarrharr/awesome-cli-apps) — Developer Tools 카테고리
- [ ] [awesome-shell](https://github.com/alebcay/awesome-shell) — Productivity Tools
- [ ] [awesome-claude](https://github.com/... ) — Claude 관련 리스트 (있으면)

### Month 2+ — Product Hunt

star가 50-100+ 쌓인 후 런칭하는 것이 효과적.
- "Developer Tools" 카테고리
- 런칭 전날에 Hunter 확보 (팔로워 많은 사람)
- 런칭 당일: 투표 독려 (커뮤니티에 공유)

---

## Metrics & Visibility Checklist

### npm 인기 지표 올리기

| 지표 | 방법 |
|------|------|
| **Weekly Downloads** | `npx batipanel` 홍보 (실행마다 다운로드 카운트), 블로그/README에서 npx 설치법 강조 |
| **Dependents** | starter-kit, dotfiles, dev-setup 같은 프로젝트에서 dependency로 추가 |
| **Version frequency** | 정기 릴리즈 (2-4주마다) — "recently updated" 검색 우대 |
| **README quality** | npmjs.com에 README가 그대로 표시됨 — 뱃지, GIF, 명확한 설치법 |

### GitHub 인기 지표 올리기

| 지표 | 방법 |
|------|------|
| **Stars** | Show HN, Reddit이 가장 효과적. README에 "Star this repo" CTA |
| **Star velocity** | GitHub Trending은 절대 수가 아니라 증가 속도 기반 — 런칭 집중 포화 |
| **Forks** | CONTRIBUTING.md 잘 만들어두면 자연 증가 |
| **Used by** | package.json에서 dependency로 사용하는 프로젝트 수 |
| **Contributors** | "good first issue" 라벨 붙은 이슈 만들기 → 기여자 유입 |
| **Activity** | 정기 커밋, 이슈 응답, Discussion 활동 |

### GitHub Trending 진입 조건 (비공식)

- 하루 20-50+ stars 지속 → Daily trending
- 일주일 100-200+ stars → Weekly trending
- **핵심**: 런칭 첫 주에 홍보를 집중해서 star velocity를 최대화

### 검색 최적화 (SEO)

- GitHub Topics 설정 ✅ (완료)
- npm keywords 설정 ✅ (완료)
- README 첫 줄에 키워드 포함 ✅ ("AI-powered terminal workspace manager")
- `batipanel.com` 홈페이지 → SEO + 설치 가이드 페이지

---

## Effective Branding Tips

1. **데모 GIF가 핵심** — [asciinema](https://asciinema.org) 또는 [vhs](https://github.com/charmbracelet/vhs)로 터미널 녹화, README 상단에 배치
2. **원라인 피치** — "AI-powered terminal workspace manager"
3. **원커맨드 설치** — `npx batipanel`은 강력한 셀링포인트
4. **Before/After** — 수동 tmux 설정 vs batipanel 비교
5. **소셜 프루프** — Star count 뱃지, 사용자 후기, 커뮤니티 규모
6. **일관된 브랜딩** — GitHub, npm, Twitter, 블로그에서 같은 소개 문구 + 로고 사용

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
