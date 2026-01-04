# 개발 로그 (Development Log)

> [!NOTE]
> **로그 작성 가이드**
> 1. **날짜 형식**: `## YYYY-MM-DD (요일)`
> 2. **섹션 구분**:
>    - `### [스프린트명]: [목표]`
>    - `#### ✅ 주요 작업 및 성과`: 완료된 태스크를 불렛 포인트로 기록
>    - `#### 📝 비고 / 특이사항`: 이슈, 해결 방법, 결정 사항 등 기술
>    - `#### 🔗 관련 문서`: 새로 생성되거나 참고한 문서 링크
> 3. **표기 규칙**: 중요한 파일명, 클래스, 기술 키워드는 백틱(``) 사용

---

## 2026-01-04 (일)

### 🚀 Sprint 2: 게임 로비 및 데이터 인프라 구축 (Game Lobby & Infrastructure)

#### ✅ 주요 작업 및 성과
- **게임 및 참가자 데이터 모델 설계**
    - `GameModel`, `ParticipantModel`을 정의하여 Firestore 문서 구조와 1:1 매핑
    - 게임 상태(Lobby, Playing, Finished) 및 역할(Cop, Robber) enum 도입
- **GameRepository를 통한 Firestore 트랜잭션 로직 구현**
    - 게임 생성 시 9자리 게임 코드와 `gameCodes` 매핑 문서를 원자적으로 생성
    - 코드 입력 및 QR 스캔 기반의 게임 참가 로직 구현 (데이터 무결성 보장)
    - 실시간 게임 정보 및 참가자 목록 스트림 관리
- **게임 생성 및 참가 UI 구현**
    - `CreateGameScreen`: 게임 이름, 제한 시간, 인원 비율 설정을 위한 UI 구축
    - `JoinGameScreen`: 탭 인터페이스를 통해 코드 입력 및 `mobile_scanner` 기반 QR 스캔 지원
- **실시간 대기방(Lobby) 시스템 고도화**
    - `LobbyScreen`: 참가자 리스트 실시간 업데이트 및 입장용 QR 코드(`qr_flutter`) 표시
    - **공유 기능**: `share_plus` 패키지를 연동하여 게임 번호와 초대 코드를 메시지/카톡 등으로 즉시 공유하는 기능 구현
    - **참여 현황 UI**: 목록 상단에 현재 참여 인원수를 실시간으로 표시하도록 개선
- **안전한 게임 나가기 및 생명주기 관리**
    - `GameRepository.leaveGame`: 트랜잭션을 통한 참가자 삭제 및 인원수 감소 로직 구현
    - 뒤로가기 시 "나가시겠습니까?" 확인 다이얼로그(`PopScope`)를 통해 오작동 방지
    - `AppLifecycleListener`를 활용하여 앱 종료(Detached) 시에도 자동으로 퇴장 처리 시도
- **Android 시스템 UI 대응 및 가이드 수립**
    - 안드로이드 15 에지 투 에지(Edge-to-Edge) 지원을 위해 시스템 바 투명화 작업 수행
    - 주요 화면에 `SafeArea`를 적용하여 물리/소프트웨어 네비게이션 바가 UI를 가리는 문제 해결
    - 향후 개발을 위한 [ui_guide.md](file:///d:/comon/catchrun/docs/ui_guide.md) 가이드 라인 자산화

#### 📝 비고 / 특이사항
- **QR 데이터 규격**: `catchrun:gameId:qrToken` 형식을 도입하여 타 앱의 QR 스캔과 구분하고 보안성을 확보함.
- **패키지 추가**: `mobile_scanner`, `qr_flutter`, `share_plus` 패키지를 프로젝트에 통합함.
- **디자인 철학 반영**: 전역 `SafeArea` 대신 각 화면(`Scaffold.body`)에서 개별 제어하여 디자인적 몰입감(Bleeding 효과)을 유지함.

#### 🔗 관련 문서
- [implementation_plan.md](file:///C:/Users/voll1/.gemini/antigravity\brain/34d87fcb-0a8b-4976-bd25-bc1202112fb2/implementation_plan.md) (Sprint 2 계획)
- [walkthrough.md](file:///C:/Users/voll1/.gemini/antigravity\brain/34d87fcb-0a8b-4976-bd25-bc1202112fb2/walkthrough.md) (Sprint 2 검증 결과)
- [ui_guide.md](file:///d:/comon/catchrun/docs/ui_guide.md) (시스템 UI 대응 가이드)


### 🚀 Sprint 1: 인증 및 프로필 시스템 구축 (Auth & User)

#### ✅ 주요 작업 및 성과
- **Google 로그인 연동 및 인증 인프라 구축**
    - `firebase_auth` 및 `google_sign_in` 패키지를 활용한 구글 로그인 기능 구현
    - `AuthRepository`를 통한 인증 상태(`authStateChanges`) 스트림 노출 및 관리
- **사용자 프로필 및 데이터 관리 시스템 구현**
    - Firestore `users` 컬렉션 연동 및 `UserRepository` 구현
    - `AppUser` 모델을 정의하여 닉네임, 아바타 시드 등 사용자 데이터 직렬화 처리
    - `NicknameGenerator`를 통한 한국어 기반 랜덤 닉네임 생성 로직 추가
- **네비게이션 및 상태 기반 리다이렉션 안정화**
    - `go_router`와 `riverpod`을 결합하여 인증 상태 및 프로필 완성도에 따른 자동 라우팅 구현
    - `refreshListenable`을 적용하여 비동기 데이터(Auth, Profile) 변화에 즉각 반응하는 라우터 구조 확립
    - 로그인/온보딩 도중 앱 종료 시에도 마지막 단계를 기억하는 '가입 절차 복구 로직' 적용
- **에러 핸들링 및 디버깅 도구 강화**
    - `LoginScreen` 및 `OnboardingScreen`에 에러 시 스낵바 노출 로직 추가
    - `AuthController` 내 상세 디버그 로그(`print`) 추가로 문제 추적 용이성 확보

#### 📝 비고 / 특이사항
- **SHA-1 등록 이슈**: 구글 로그인 시 `ApiException: 10` 에러 발생. Firebase 콘솔에 디버그용 SHA-1 지문을 등록하여 해결함.
- **라우터 리팩토링**: `GoRouter`가 매번 재생성되는 문제를 해결하기 위해 `Provider` 안에서 `refreshListenable`을 사용하는 방식으로 구조를 안정화함.
- **유령 회원 관리**: 가입 후 프로필 설정을 마치지 않고 방치된 사용자를 위해 Cloud Functions 기반의 자동 삭제 시스템을 설계함.

#### 🔗 관련 문서
- [implementation_plan.md](file:///C:/Users/voll1/.gemini/antigravity\brain/1cb021c6-df46-4799-9c3c-8636de46b6c1/implementation_plan.md) (Sprint 1 계획)
- [user_cleanup_design.md](file:///d:/comon/catchrun/docs/user_cleanup_design.md) (유령 회원 삭제 설계서)
- [walkthrough.md](file:///C:/Users/voll1/.gemini/antigravity\brain/1cb021c6-df46-4799-9c3c-8636de46b6c1/walkthrough.md) (Sprint 1 검증 결과)


### 🚀 Sprint 0: 프로젝트 기반 구축 (Foundation)

#### ✅ 주요 작업 및 성과
- **프로젝트 초기화 및 형상 관리 설정**
    - Flutter 프로젝트 생성 및 패키지명/번들ID(`com.comon.catchrun`) 확정
    - 원격 저장소 연결 및 Git 브랜치 전략(`main`, `dev`, `feat/*`, `fix/*`) 수립 (`git_strategy.md`)
- **Firebase 연동 및 환경 최적화**
    - Firebase 프로젝트 생성 및 iOS/Android 앱 연동 (GoogleService-Info.plist, google-services.json)
    - `firebase_analytics` 등 플러그인 호환성을 위한 `minSdkVersion` 업데이트 (19 -> 23)
- **앱 아키텍처 및 라우팅 구축**
    - `go_router`를 활용한 기본 라우팅 설정 (`/splash`, `/login`, `/onboarding`, `/home`)
    - Material 3 기반 공통 테마 및 버튼/카드와 같은 핵심 UI 컴포넌트 스켈레톤 구현
- **문서화 및 태스크 관리**
    - 화면 정의서(`screenspecification.md`) 및 태스크 보드(`task_board.md`) 작성
    - 스프린트 단계별 목표 및 DoD(Definition of Done) 정의

#### 📝 비고 / 특이사항
- Android SDK 버전 이슈로 `minSdkVersion`을 23으로 상향 조정함.
- Sprint 0가 안정적으로 완료되어 다음 단계인 Sprint 1(인증/프로필) 진행 가능 상태임.
