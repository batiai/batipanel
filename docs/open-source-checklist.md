# 오픈소스 공개 체크리스트

batipanel을 퍼블릭 저장소로 전환하기 위한 체크리스트.

---

## 공개 전 확인사항

### 코드 & 파일 점검

- [ ] 하드코딩된 API 키, 토큰, 비밀번호 없는지 확인
- [ ] 내부 서버 주소, IP, 도메인 없는지 확인
- [ ] 개인정보(이메일, 전화번호 등) 없는지 확인
- [ ] .env 파일이 .gitignore에 포함되어 있는지 확인
- [ ] 불필요한 테스트 데이터, 로그 파일 없는지 확인

### 라이선스 & 문서

- [x] LICENSE 파일 (MIT)
- [x] README.md — 설치, 사용법, 레이아웃, 키보드 단축키
- [x] CONTRIBUTING.md — 기여 가이드
- [ ] CODE_OF_CONDUCT.md (선택)
- [ ] SECURITY.md (선택 — 보안 취약점 리포팅 방법)

### 배포 채널

- [ ] npm: `npm publish --access public`
- [ ] Homebrew: `batiai/homebrew-tap` 저장소 생성 + Formula 배치
- [ ] curl installer: `batipanel.com/install.sh` 리다이렉트 설정
- [ ] GitHub Release: 태그 생성 + 릴리즈 노트

### CI/CD

- [x] GitHub Actions CI: ShellCheck + syntax + install test
- [ ] (선택) npm publish 자동화 워크플로우
- [ ] (선택) Homebrew formula 자동 업데이트

---

## Git 히스토리 관련

### 현재 히스토리 그대로 공개하는 경우

저장소를 public으로 전환하면 **모든 git 히스토리가 공개**됨:
- 모든 커밋 메시지
- 모든 코드 변경 diff
- 커밋 작성자 이름, 이메일
- 브랜치 히스토리

### 클린 히스토리로 시작하는 경우

민감한 내용이 히스토리에 있다면 새 저장소로 시작:

```bash
# 방법 1: squash — 전체 히스토리를 하나의 커밋으로
git checkout --orphan clean
git add -A
git commit -m "Initial release v0.3.0"
git branch -M clean master
git push origin master --force

# 방법 2: 새 저장소 생성
mkdir batipanel-public
cp -r batipanel-cli/* batipanel-public/
cd batipanel-public
git init
git add -A
git commit -m "Initial release v0.3.0"
git remote add origin git@github.com:batiai/batipanel.git
git push -u origin master
```

### 권장 사항

현재 히스토리를 확인해서:
- **민감 정보 없음** → 그대로 public 전환 (히스토리 보존이 오픈소스 신뢰도에 도움)
- **민감 정보 있음** → squash 후 공개 또는 새 저장소

---

## GitHub 저장소 설정

### 저장소 이름 변경

```
Settings → General → Repository name → "batipanel" → Rename
```

GitHub가 `batipanel-cli` → `batipanel` 자동 리다이렉트 설정.

### 로컬 remote 업데이트

```bash
git remote set-url origin git@github.com:batiai/batipanel.git
```

### 공개 전환

```
Settings → General → Danger Zone → Change repository visibility → Make public
```

### 권장 저장소 설정

- Topics: `tmux`, `claude`, `ai`, `terminal`, `workspace`, `developer-tools`
- Description: "AI-powered terminal workspace manager"
- Website: `https://batipanel.com`
- [x] Issues 활성화
- [x] Discussions 활성화 (선택)
- [ ] Wiki 비활성화 (README/docs로 충분)
- [ ] Projects 비활성화 (필요할 때 활성화)

### Branch protection (공개 후)

```
Settings → Branches → Add rule → master
  ✓ Require pull request reviews
  ✓ Require status checks to pass (CI)
  ✓ Require branches to be up to date
```
