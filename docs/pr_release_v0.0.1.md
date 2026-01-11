# Pull Request: 캐치런 v0.0.1 MVP 릴리즈

## 📦 릴리즈 정보
- **버전**: v0.0.1+1
- **타입**: MVP (Minimum Viable Product) 초기 버전
- **스프린트**: Sprint 0-6 통합
- **PR 타입**: `dev` → `main`

---

## ✨ 주요 기능

### 🔐 인증 시스템 (Sprint 1)
- Google 로그인 및 게스트(익명) 로그인 지원
- 사용자 프로필 관리(닉네임, 아바타)
- 자동 랜덤 닉네임 생성 기능

### 🎮 게임 코어 시스템 (Sprint 2-4)
- 게임 생성 및 코드/QR 기반 참가 기능
- 실시간 대기방(로비) 및 참가자 관리
- 역할 배정 시스템(경찰/도둑 수동 배정)
- QR 스캔 기반 체포 및 구출 메커니즘
- 감옥 화면 및 자동 상태 전환
- 실시간 타이머 및 게임 진행 상태 모니터링

### 🔑 특수 아이템 (Sprint 5)
- NFC 기반 감옥 열쇠 시스템
  - 방장의 NFC 카드 기록 기능
  - 수감자의 NFC 카드 스캔을 통한 탈출
- 실시간 게임 이벤트 알림(체포/구출/열쇠 사용)

### 🏆 점수 및 결과 (Sprint 6)
- 정밀 점수 산정 시스템(체포, 구출, 생존 점수)
- 자동 승리 판정 로직
- 특별 칭호 시스템(검거왕, 구출왕, 불사조, MVP)
- 리더보드 및 결과 화면

---

## 🎨 UI/UX 개선

### 디자인 시스템
- **테마**: Futuristic HUD, Neon, Glassmorphism 컨셉 전면 적용
- **공통 위젯**: 300+ 라인의 중복 코드 제거 및 재사용성 향상
- **주요 컴포넌트**: `HudText`, `GlassContainer`, `SciFiButton`, `GradientBorder`, `HudSectionHeader`, `ParticipantCounter`

### 화면별 리디자인
- **로그인 및 스플래시**: 가로/세로 배경 이미지 대응, 로고 이미지 적용
- **프로필 설정**: 플로팅 애니메이션, 네온 효과, 글래스모피즘 패널
- **홈 화면**: 글래스모피즘 프로필 섹션, 네온 그라데이션 버튼
- **게임 생성/참가**: HUD 스타일 입력 폼, QR 스캔 오버레이
- **로비**: 전투 대기실 컨셉, 커스텀 다이얼로그, 네온 테마
- **플레이/감옥/QR 스캔**: 역할별 테마(경찰:블루, 도둑:레드), 네온 타이머
- **결과 화면**: 승리 진영별 컬러, 트로피 배너, HUD 스타일 순위표

---

## 🔒 보안 강화
- `flutter_dotenv` 기반 환경 변수 관리 도입
- Firebase API Key 및 민감 정보 `.env` 파일로 분리
- Git 히스토리 정화(노출된 API Key 영구 제거)
- Firebase 중복 초기화 방지 로직 적용
- `.env.example` 템플릿 제공

---

## 🛠 기술 스택 및 환경

### Flutter & Platform
- **Flutter SDK**: 최신 안정 버전
- **Android**: 
  - minSdkVersion: 23
  - compileSdk: 36
  - AGP 8.7.3, Gradle 8.9, Kotlin 2.1.0
  - JVM Target: 17

### Firebase
- Firebase Authentication
- Cloud Firestore
- Firebase Analytics

### 주요 패키지
- `riverpod` - 상태 관리
- `go_router` - 선언적 라우팅
- `mobile_scanner` - QR 코드 스캔
- `qr_flutter` - QR 코드 생성
- `nfc_manager` - NFC 통신
- `flutter_dotenv` - 환경 변수 관리
- `share_plus` - 공유 기능
- `google_sign_in` - Google 인증

---

## 📝 코드 품질

### 린트 및 분석
- ✅ `flutter analyze` 실행 시 **No issues found!** 달성
- ✅ `use_build_context_synchronously` 린트 이슈 전수 해결
- ✅ deprecated API 최신화 (`withOpacity` → `withValues`)

### 코드 구조 개선
- ✅ 체계적인 디렉토리 구조 수립
  - `lib/core/widgets/`: 앱 전체 공통 위젯
  - `lib/features/[feature]/widgets/`: feature별 전용 위젯
- ✅ Screen 파일 내 로컬 위젯 분리 (6개 위젯)
  - `onboarding_screen.dart`: 397 → 176 라인 (55% 감소)
  - `join_game_screen.dart`: 436 → 361 라인 (17% 감소)

---

## 🔗 관련 문서
- [개발 로그](development_log.md)
- [Git 브랜치 전략](.agent/rules/git-strategy.md)
- [UI 가이드](ui_guide.md)
- [Firebase 스키마](firebase_schema.md)
- [화면 정의서](screenspecification.md)

---

## ⚠️ 알려진 이슈 및 향후 개선 사항

### 게임 밸런스
- [ ] 점수 밸런스 조정 필요
  - 현재: 도둑의 생존 점수가 플레이 시간에 비례하여 경찰의 체포 점수를 초과할 수 있음
  - 개선: 플레이 시간에 따라 경찰의 체포 점수도 비례하여 증가하도록 조정 필요

### 예외 처리
- [ ] 게임 종료 타이밍과 체포/구출 트랜잭션 동시 발생 시 예외 처리 강화 필요

---

## 🔢 변경 통계
- **총 110개 파일 변경**
- **+7,719 라인 추가 / -145 라인 삭제**
- **23개의 커밋** (Sprint 0-6)

### 주요 커밋
```
64ee370 chore: set release bundle version 0.0.1+1
637999a refactor: extract common widgets and separate screen-local widgets
8c43c6d feat: implement manual role assignment, lobby UI refinement, and play screen for sprint 3
f99460a chore: secure firebase api keys and integrate flutter_config
ef03559 feat: implement sprint 1 authentication and user profile system
```

---

## 📌 체크리스트

### 기능 검증
- [x] 관련 화면/유즈케이스 동작 확인
- [x] Firestore 필드 변경 호환성 검토
- [x] iOS/Android 빌드 확인
- [x] 보안 규칙 점검

### 코드 품질
- [x] 린트 이슈 해결
- [x] 문서화 완료
- [x] 공통 위젯 추출 및 리팩토링

### 보안
- [x] API Key 환경 변수 분리
- [x] Git 히스토리 정화
- [x] Firebase 보안 규칙 검토

---

## 📋 PR 제목 (GitHub용)
```
release: 캐치런 v0.0.1 MVP 릴리즈 (Sprint 0-6 통합)
```

---

**이 PR은 CatchRun MVP의 첫 릴리즈 후보로, Sprint 0부터 Sprint 6까지의 모든 작업을 통합합니다.**
