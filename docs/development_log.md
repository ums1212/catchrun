# 개발 로그 (Development Log)

> [!NOTE]
> **로그 작성 가이드**
> 1. **날짜 형식**: `## YYYY-MM-DD (요일)`
> 2. **섹션 구분**:
>    - `### [스프린트명]: [목표]`
>    - `#### ✅ 주요 작업 및 성과`: 완료된 태스크를 불렛 포인트로 기록
>    - `#### 📝 비고 / 특이사항`: 이슈, 해결 방법, 결정 사항 등 기술
>    - `#### 🔗 관련 문서`: 새로 생성되거나 참고한 문서 링크
>    - `#### 🔗 관련 문서`: 새로 생성되거나 참고한 문서 링크
> 3. **표기 규칙**: 중요한 파일명, 클래스, 기술 키워드는 백틱(``) 사용

---

## 2026-01-07 (수)

### 🚀 앱 아이콘 설정 (App Icon Setup)

#### ✅ 주요 작업 및 성과
- **`flutter_launcher_icons` 패키지 도입 및 설정**
    - `pubspec.yaml`에 `flutter_launcher_icons` 종속성 추가 및 아이콘 경로(`assets/icon/app_icon.png`) 설정
    - 안드로이드 Adaptive Icon 지원을 위한 배경색(`#FFFFFF`) 및 전경 이미지 설정 적용
- **플랫폼별 앱 아이콘 자동 생성**
    - 안드로이드: `launcher_icon.png`, `ic_launcher.png` 등 레거시 및 어댑티브 아이콘 세트 생성
    - iOS: `AppIcon.appiconset` 내 다양한 해상도(20x20 ~ 1024x1024)의 아이콘 파일 일괄 생성 및 적용

---

### 🚀 앱 이름 다국어 설정 (App Name Localization)

#### ✅ 주요 작업 및 성과
- **Android 앱 이름 다국어화**
    - `res/values/strings.xml`: 기본 앱 이름을 "CatchRun"으로 설정
    - `res/values-ko/strings.xml`: 한국어 앱 이름을 "캐치런"으로 설정
    - `AndroidManifest.xml`: `android:label`을 `@string/app_name` 참조 방식으로 변경
- **iOS 앱 이름 다국어화**
    - `en.lproj/InfoPlist.strings`: 영어 표시 이름을 "CatchRun"으로 설정
    - `ko.lproj/InfoPlist.strings`: 한국어 표시 이름을 "캐치런"으로 설정
    - `Info.plist`: `CFBundleDisplayName` 및 `CFBundleName`을 "CatchRun"으로 통일하여 기본값 설정

#### 📝 비고 / 특이사항
- 시스템 언어 설정에 따라 홈 화면 및 설정 메뉴에서 앱 이름이 영어 또는 한국어로 자동 전환됨을 확인하기 위한 기초 설정을 마침.


---

## 2026-01-06 (월)

### 🚀 Sprint 6: 점수/결과/칭호 및 코드 폴리싱 (Scoring, Results & Polishing)

#### ✅ 주요 작업 및 성과
- **정밀 점수 및 승리판정 로직 구현**
    - `GameRepository`: 경찰 승리(도둑 전원 수감) 및 도둑 승리(시간 초과 시 생존자 존재) 판정 로직 정립
    - **생존 점수(Survival Score)**: 도둑의 생존 시간에 비례한 점수 자동 계산 및 `lastStateChangedAt` 기반 통계 처리
    - 체포(100점), 구출(50점), 열쇠 사용 등 행동별 가산점 시스템 통합
- **최종 결과 화면(ResultScreen) 및 리더보드 구축**
    - 승리 진영 강조 배너 및 게임 통계 시각화 레이아웃 구현
    - **특별 칭호 시스템**: 검거왕(Most Catches), 구출왕(Most Rescues), 불사조(Longest Survival), MVP 산출 로직 적용
    - 전체 참가자 점수 기반 실시간 리더보드 정렬 기능 추가
- **코드 품질 안정화 및 린트 오류 전수 해결**
    - `use_build_context_synchronously` 경고 해결: 프로젝트 전반의 비동기 갭 보호 로직을 `State.mounted` 패턴으로 통일
    - `Navigator` 및 `ScaffoldMessenger` 사전 캡처 방식을 통한 컨텍스트 참조 안정성 확보

#### 📝 비고 / 특이사항
- **기술적 결정**: `StatefulWidget` 내부에서는 `context.mounted`보다 `State.mounted` 속성을 사용하는 것이 린터와의 호환성 및 안정성 면에서 유리함을 확인하여 전면 수정함.
- **UX 개선**: 게임 종료 시 모든 참가자가 즉시 결과 화면으로 자동 이동되도록 이벤트 기반 라우팅을 강화함.
- 플레이 시간이 많아질수록 도둑의 생존점수가 많아져서 만약 2인 게임에서 도둑이 2분만 생존해도 생존점수 120점으로 체포점수 100점인 경찰보다 점수가 높아 1등을 하게 되기 때문에 승패의 의미가 사라짐. 플레이 시간에 따라 경찰의 체포점수도 비례하게 늘어날 수 있도록 점수 밸런스 패치가 필요.
- 게임 시간이 끝날 때와 도둑 체포 또는 구출 타이밍이 겹칠 때 오류가 발생할 수 있는지 확인 필요

---

### 🚀 Sprint 5: NFC 감옥 열쇠 및 실시간 이벤트 알림 (NFC Prison Key & Event Popups)

#### ✅ 주요 작업 및 성과
- **NFC 기반 감옥 열쇠 시스템 구현**
    - **NFC 기록(Write)**: `LobbyScreen`에서 방장이 빈 NFC 카드에 고유한 `nfcKeyId`를 NDEF 형식으로 기록하는 기능 구현
    - **NFC 사용(Read)**: `PrisonScreen`에서 수감된 도둑이 기록된 카드를 접촉하여 즉시 탈출(free 상태 전환)하는 프로세스 구축
    - **보안 및 제약**: 열쇠 사용 시 5분간 타인 구출 불가 제약(`rescueDisabledUntil`) 및 트랜잭션 계층의 데이터 무결성 검증 적용
    - **UX 개선**: NFC 미지원/비활성화 시 안내 다이얼로그 제공 및 시스템 설정 연결 로직 추가
- **실시간 게임 이벤트 알림 시스템(Event Popups) 도입**
    - `PlayScreen`에서 Firestore `events` 컬렉션을 실시간 구독하여 게임 내 주요 변화 감지
    - `EventPopupOverlay`: 체포, 구출, 열쇠 사용 이벤트를 애니메이션과 함께 화면 중앙에 시각화하여 강조
    - 중복 노출 방지를 위한 `eventId` 캐싱 로직 적용
- **Android 빌드 시스템 안정화 및 패키지 마이그레이션**
    - **Kotlin 2.1.0 / Gradle 8.9 / AGP 8.7.3** 기반의 최신 빌드 환경 구축 및 증분 빌드 오류 조치
    - `nfc_manager` 4.x 및 `ndef_record` 모듈화에 따른 대대적인 API 마이그레이션 수행

#### 📝 비고 / 특이사항
- **API 대응**: `nfc_manager` v4의 파괴적 변경사항(명명된 파라미터 필수화 등)을 전수 반영하고, 유실된 `createText` 기능을 커스텀 헬퍼로 대체함.

---

## 2026-01-05 (월)

### 🚀 Sprint 4: QR 판정 시스템 및 감옥 화면 구현 (QR Catch/Rescue & Prison Screen)

#### ✅ 주요 작업 및 성과
- **QR 기반 체포 및 구출 시스템 완성**
    - `catchRobber`: 경찰이 도둑의 QR을 스캔하여 수감시키는 Firestore 트랜잭션 구현 (체포 점수 100점)
    - `rescueRobber`: 자유 도둑이 수감된 동료의 QR을 스캔하여 석방시키는 트랜잭션 구현 (구출 점수 50점)
    - `QrScanScreen`: `mobile_scanner`를 이용한 실시간 QR 인식 및 게임 데이터 검증 로직 통합
- **수감자 전용 감옥 화면(PrisonScreen) 및 자동 전환**
    - 도둑이 `jailed` 상태가 되면 자동으로 감옥 화면으로 전환되는 전용 UI 구축 (S-09)
    - 본인의 구출용 QR 코드를 크게 표시하고 이동 불가 룰에 대한 안내 제공
    - 석방(free 상태) 감지 시 자동으로 플레이 화면으로 복귀하는 실시간 모니터링 로직 구현
- **상세 활동 기록(Events Collector) 도입**
    - "누가 누구를 체포했다", "누가 누구를 구출했다" 등 게임 내 모든 주요 활동을 상세 페이로드와 함께 `events` 컬렉션에 기록
    - 입장(`PLAYER_JOINED`), 퇴장(`PLAYER_LEFT`) 등 참가자 상태 변화에 대한 자동 로그 연동
- **게임 안정성 및 예외 케이스 처리**
    - 타 게임의 QR 스캔 방지 및 본인 QR 스캔 차단 로직 적용
    - `PlayScreen`: 도둑 플레이어가 언제든 본인의 구출 QR을 띄울 수 있는 다이얼로그 오버레이 추가

#### 📝 비고 / 특이사항
- **버그 수정**: 게임 시작 시 도둑 인원수(`robbersFree`)가 0으로 초기화되어 즉시 종료되는 문제를 해결함. `startGame` 트랜잭션 내에서 실제 참가자 수를 집계하여 초기화하도록 개선.
- **동기화 유예**: 네트워크 지연으로 인한 오동작을 방지하기 위해 게임 시작 후 2초간은 종료 조건을 보류하는 안전 장치 추가.
- **향후 계획**: Sprint 5(NFC 열쇠)와 Sprint 6(결과 화면) 진행 예정.

---


### 🚀 Sprint 3: 역할 배정 및 게임 프로세스 완성 (Role Assignment & Game Flow)

#### ✅ 주요 작업 및 성과
- **역할 관리 시스템 고도화 및 단순화**
    - 현장 합의를 우선시하는 정책에 따라 '경찰 지원' 및 '자동 역할 배정(Shuffle)' 기능을 제거하고 방장 직접 지정 방식으로 전환
    - `LobbyScreen`: 참가자 목록에 역할 아이콘(👮 경찰, 🏃 도둑) 및 방장 표시(⭐)를 통해 직관적인 역할 시각화 제공
    - `RoleChangeBottomSheet`: 방장이 참가자를 클릭하여 역할을 즉시 변경할 수 있는 관리 UI 구현
- **게임 시작 전 데이터 정밀 검증**
    - '게임 시작' 버튼 클릭 시 현재 배정된 경찰 수와 방 설정(`copsCount`)의 일치 여부를 확인하는 유효성 검사 로직 추가
    - 조건 미충족 시 안내 다이얼로그를 통해 현장 조율을 유도하여 게임 규칙 위반 방지
- **플레이 화면(PlayScreen) 및 실시간 타이머 구현**
    - `/play/:gameId` 경로를 통한 플레이 화면 진입 및 역할별 테마(경찰: 파랑, 도둑: 빨강) 동적 적용
    - Firestore의 `endsAt` 타임스탬프를 기반으로 한 오차 없는 실시간 카운트다운 타이머 구현
    - 전체 도둑, 수감된 도둑, 탈출 중인 도둑 수를 한눈에 볼 수 있는 게임 상태 대시보드 구축
- **자동 게임 종료 및 결과 처리 인프라**
    - 실시간 데이터 감지를 통한 게임 종료 조건 구현 (제한 시간 만료 또는 모든 도둑 수감 시 종료)
    - 종료 시 `status=finished` 업데이트 및 `GAME_ENDED` 이벤트 기록 연동
    - 현재 결과 화면 부재로 인한 임시 홈 화면 리다이렉션 처리

#### 📝 비고 / 특이사항
- **정책 변경**: 사용자 피드백을 반영하여 복잡한 알고리즘(wantsCop, roleLock)보다는 직관적인 방장 제어 방식으로 로직을 단순화하여 사용성을 개선함.
- **빌드 및 스코프 관리**: `ListView.builder` 내부의 변수 스코프 문제와 `go_router` 임포트 누락으로 발생했던 빌드 에러를 수정하여 안정성을 확보함.

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
    - 향후 개발을 위한 `docs/ui_guide.md` 가이드 라인 자산화

#### 📝 비고 / 특이사항
- **QR 데이터 규격**: `catchrun:gameId:qrToken` 형식을 도입하여 타 앱의 QR 스캔과 구분하고 보안성을 확보함.
- **패키지 추가**: `mobile_scanner`, `qr_flutter`, `share_plus` 패키지를 프로젝트에 통합함.
- **디자인 철학 반영**: 전역 `SafeArea` 대신 각 화면(`Scaffold.body`)에서 개별 제어하여 디자인적 몰입감(Bleeding 효과)을 유지함.

#### 🔗 관련 문서
- [ui_guide.md](docs/ui_guide.md)

---


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
- [user_cleanup_design.md](docs/user_cleanup_design.md)

---


### 🚀 Sprint 0: 프로젝트 기반 구축 (Foundation)

#### ✅ 주요 작업 및 성과
- **프로젝트 초기화 및 형상 관리 설정**
    - Flutter 프로젝트 생성 및 패키지명/번들ID(`com.comon.catchrun`) 확정
    - 원격 저장소 연결 및 Git 브랜치 전략(`main`, `dev`, `feat/*`, `fix/*`) 수립 (`docs/git_strategy.md`)
- **Firebase 연동 및 환경 최적화**
    - Firebase 프로젝트 생성 및 iOS/Android 앱 연동 (GoogleService-Info.plist, google-services.json)
    - `firebase_analytics` 등 플러그인 호환성을 위한 `minSdkVersion` 업데이트 (19 -> 23)
- **앱 아키텍처 및 라우팅 구축**
    - `go_router`를 활용한 기본 라우팅 설정 (`/splash`, `/login`, `/onboarding`, `/home`)
    - Material 3 기반 공통 테마 및 버튼/카드와 같은 핵심 UI 컴포넌트 스켈레톤 구현
- **문서화 및 태스크 관리**
    - 화면 정의서(`docs/screenspecification.md`) 및 태스크 보드(`docs/task_board.md`) 작성
    - 스프린트 단계별 목표 및 DoD(Definition of Done) 정의

#### 📝 비고 / 특이사항
- Android SDK 버전 이슈로 `minSdkVersion`을 23으로 상향 조정함.
- Sprint 0가 안정적으로 완료되어 다음 단계인 Sprint 1(인증/프로필) 진행 가능 상태임.
