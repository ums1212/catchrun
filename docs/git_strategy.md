# 추천 브랜치 전략 (MVP용, 단순·안전)
## 브랜치
- `main` : 항상 배포 가능한 상태(green)
- `dev` : 통합 브랜치(기능 머지되는 곳, QA 대상)
- `feat/*` : 기능 개발 브랜치
- `fix/*` : 버그 수정 브랜치(급하면 main에서 분기)
- `release/*` : 스토어/테스트플라이트 올리기 직전 “고정” 브랜치(선택)
- `hotfix/*` : 운영 이슈 대응(선택)

## 흐름
### 1) 일반 개발
1. dev에서 기능 브랜치 생성
    - feat/auth-google
    - feat/lobby-join-qr
2. 기능 완료 후 PR → dev로 머지
3. dev가 안정되면 main으로 PR 머지(릴리즈 컷)

### 2) 릴리즈(선택: release 브랜치)
- 스토어/테스트 업로드 직전
1. release/0.1.0을 dev에서 분기
2. 릴리즈 브랜치에는 버그픽스만 머지
3. 배포 후 main에 머지 + dev에도 동기화(back-merge)

### 3) 긴급 수정(hotfix)
- 운영 장애/크래시급이면
1. hotfix/crash-on-login을 main에서 분기
2. 수정 후 main에 머지
3. 같은 커밋을 dev에도 체리픽/머지

## 브랜치 네이밍 규칙
- `feat/<ticket>-<short>` (티켓 없으면 날짜/스프린트)
  - `feat/s3-role-assign`
- `fix/<scope>-<short>`
  - `fix/qr-parse-null`
- `release/<semver>`
  - `release/0.1.0`
- `hotfix/<short>`
  - `hotfix/firestore-rules`

## 커밋/PR 규칙 (추천)
### 커밋 메시지(Conventional Commits)
- `feat`: google auth login
- `fix`: prevent duplicate catch transaction
- `refactor`: split firestore repositories
- `chore`: bump flutter version

### PR 템플릿 체크리스트
- 관련 화면/유즈케이스 동작 확인
- Firestore 필드 변경 시 마이그레이션/호환성 고려
- iOS/Android 둘 다 빌드 확인(최소한 CI라도)
- 보안 규칙/권한 영향 확인

### 태그 & 버전 전략
- main 머지 시 태그 찍기: v0.1.0, v0.1.1
- 내부적으로는 pubspec.yaml 버전도 같이 올리기
- Firebase(Functions/Rules) 변경이 있으면 같은 PR에 포함시키거나 최소한 “릴리즈 노트”에 명시

### Flutter + Firebase에서 특히 중요한 포인트
1. **Firestore 스키마 변경은 “역호환”**을 우선
    - 필드 추가는 안전
    - 필드 제거/타입 변경은 위험 → 단계적 마이그레이션
2. 보안 규칙은 코드와 같이 버전 관리
    - firebase/ 디렉토리로 rules, indexes, functions 관리 추천
3. dev에 머지되면 바로 깨지지 않게
    - “Feature Flag”를 써서 UI는 붙여도 기능은 꺼둘 수 있게 하면 안정적

### 영 추천 세팅(간단 CI)
- PR마다:
  - flutter analyze
  - flutter test
  - flutter build apk --debug (최소)
- 릴리즈 브랜치/태그:
  - flutter build ipa(또는 Xcode Cloud), flutter build appbundle

### 최종 추천 운영 예시(현실적으로)

- 하루 작업 시작:
  - git checkout dev && git pull
  - git checkout -b feat/play-qr-catch
- AI에게 작업 지시 → 커밋
- 로컬에서 flutter analyze + 실행 확인
- feat/* → dev 머지
- 스프린트 끝:
  - dev 안정 확인 → main 머지 + 태그