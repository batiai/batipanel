# batipanel 배포 가이드

npm, Homebrew, shell script 세 가지 채널로 배포하는 방법.

---

## 1. npm / npx 배포

### 사전 준비

```bash
# npm 계정 로그인 (최초 1회)
npm login
```

### 배포 절차

```bash
# 1. 버전 업데이트
# package.json의 version과 VERSION 파일을 동일하게 맞춤
vim package.json   # "version": "0.3.1"
echo "0.3.1" > VERSION

# 2. 배포
npm publish --access public

# 3. 확인
npm info batipanel
npx batipanel --version
```

### 버전 업데이트 시

```bash
# patch (0.3.0 → 0.3.1): 버그 수정
npm version patch

# minor (0.3.0 → 0.4.0): 새 기능
npm version minor

# major (0.3.0 → 1.0.0): 호환성 깨지는 변경
npm version major

# npm version 명령은 package.json을 자동 수정하고 git tag도 생성함
# VERSION 파일은 수동으로 맞춰야 함
```

### 동작 원리

```
사용자: npm install -g batipanel
  ↓
npm registry에서 package.json의 files 목록 다운로드
  ↓
postinstall 훅 실행 → bash install.sh
  ↓
install.sh가 ~/.batipanel/에 파일 복사 + 의존성 설치
  ↓
bin/cli.sh가 글로벌 PATH에 링크됨 → /usr/local/bin/batipanel
```

```
사용자: npx batipanel
  ↓
임시 디렉토리에 다운로드 → postinstall로 ~/.batipanel/ 설치
  ↓
bin/cli.sh 실행 → ~/.batipanel/bin/start.sh로 위임
  ↓
임시 파일 삭제, ~/.batipanel/은 영구 보존
```

### 주요 파일

| 파일 | 역할 |
|---|---|
| `package.json` | npm 패키지 메타데이터, files 목록, postinstall 훅 |
| `bin/cli.sh` | npm bin 진입점 → ~/.batipanel/bin/start.sh 위임 |
| `.npmignore` | npm 패키지에서 제외할 파일 목록 |
| `install.sh` | postinstall에서 실행되는 실제 설치 스크립트 |

---

## 2. Homebrew 배포

### 사전 준비

1. **homebrew-tap 저장소 생성**
   - GitHub에 `batiai/homebrew-tap` 퍼블릭 저장소 생성
   - `Formula/` 디렉토리 생성

2. **Formula 파일 배치**
   ```bash
   # 이 프로젝트의 Formula/batipanel.rb를 tap 저장소로 복사
   cp Formula/batipanel.rb /path/to/homebrew-tap/Formula/batipanel.rb
   ```

### 배포 절차

```bash
# 1. 릴리즈 태그 생성 & 푸시
git tag v0.3.1
git push origin v0.3.1

# 2. GitHub에서 Release 생성 (선택사항이지만 권장)
gh release create v0.3.1 --title "v0.3.1" --notes "버그 수정"

# 3. sha256 해시 계산
curl -sL https://github.com/batiai/batipanel/archive/refs/tags/v0.3.1.tar.gz | shasum -a 256

# 4. homebrew-tap 저장소의 Formula 업데이트
# Formula/batipanel.rb에서 url과 sha256 수정:
#   url "https://github.com/batiai/batipanel/archive/refs/tags/v0.3.1.tar.gz"
#   sha256 "<위에서 계산한 해시>"

# 5. homebrew-tap에 커밋 & 푸시
cd /path/to/homebrew-tap
git add Formula/batipanel.rb
git commit -m "batipanel 0.3.1"
git push

# 6. 확인
brew update
brew upgrade batipanel
```

### 동작 원리

```
사용자: brew tap batiai/tap
  ↓
github.com/batiai/homebrew-tap 클론 → Formula/batipanel.rb 읽음
  ↓
사용자: brew install batipanel
  ↓
depends_on으로 tmux, lazygit, btop, yazi, eza 자동 설치
  ↓
url에서 tar.gz 다운로드 → sha256 검증
  ↓
install 메서드: /usr/local/share/batipanel/에 파일 복사
  ↓
wrapper 스크립트 생성: /usr/local/bin/batipanel
  ↓
post_install: ~/.tmux.conf에 batipanel config source 추가
```

```
사용자: batipanel myproject
  ↓
/usr/local/bin/batipanel (wrapper)
  ↓
brew 버전 vs ~/.batipanel/ 버전 비교 → 다르면 동기화
  ↓
~/.batipanel/bin/start.sh 실행
```

### 주요 파일

| 파일 | 역할 |
|---|---|
| `Formula/batipanel.rb` | Homebrew formula — 설치 스크립트, 의존성, wrapper |
| `homebrew-tap/Formula/batipanel.rb` | tap 저장소에 배치하는 실제 formula |

---

## 3. Shell script 배포 (curl)

### 설정

`batipanel.com/install.sh`가 GitHub raw URL로 리다이렉트되도록 설정:

```
https://batipanel.com/install.sh
  → https://raw.githubusercontent.com/batiai/batipanel/master/install.sh
```

**방법 A: Cloudflare/Vercel redirect rule**
```
/install.sh → 302 → https://raw.githubusercontent.com/batiai/batipanel/master/install.sh
```

**방법 B: nginx**
```nginx
location = /install.sh {
    return 302 https://raw.githubusercontent.com/batiai/batipanel/master/install.sh;
}
```

**방법 C: 정적 파일 (bootstrap)**
```bash
#!/usr/bin/env bash
# batipanel.com/install.sh — thin bootstrap
exec curl -fsSL https://raw.githubusercontent.com/batiai/batipanel/master/install.sh | bash
```

### 동작 원리

```
사용자: curl -fsSL https://batipanel.com/install.sh | bash
  ↓
install.sh 다운로드 & 실행
  ↓
git clone https://github.com/batiai/batipanel.git ~/.batipanel-src (또는 직접 복사)
  ↓
의존성 설치 (tmux, lazygit, btop, yazi, eza, claude)
  ↓
~/.batipanel/에 파일 복사
  ↓
PATH에 alias 추가 (b → batipanel)
```

---

## 릴리즈 체크리스트

새 버전 배포 시 순서:

```
1. VERSION 파일 업데이트
2. package.json version 업데이트
3. git commit & tag
4. git push && git push --tags
5. GitHub Release 생성 (gh release create)
6. npm publish --access public
7. homebrew-tap Formula의 url + sha256 업데이트
8. homebrew-tap 커밋 & 푸시
```

### 버전 동기화 포인트

| 위치 | 파일 | 필드 |
|---|---|---|
| 소스 | `VERSION` | 파일 내용 전체 |
| npm | `package.json` | `"version"` |
| brew | `Formula/batipanel.rb` | `url` 내 태그, `sha256` |
| git | tag | `v{VERSION}` |

네 곳의 버전이 항상 일치해야 함.
