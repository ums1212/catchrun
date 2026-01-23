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

## 2026-01-23 (목)

### 🚀 UX 개선: 로비 화면 반응형 스크롤 UI 구현 (Lobby Collapsible Game Code Card)

#### ✅ 주요 작업 및 성과
- **NestedScrollView 기반의 네이티브급 폴딩 아키텍처 및 인터랙션 구현**
    - **헤더 클릭 토글 기능**: "미션 식별 코드 ▼" 영역 클릭 시 카드가 자동으로 접히거나 펼쳐지는 편의 기능을 추가했습니다. `ScrollController` 애니메이션을 통해 부드러운 상태 전환을 제공합니다.
    - **Z-Index 겹침 문제 최종 해결**: `SliverOverlapAbsorber/Injector` 조합으로 참여 목록이 카드를 가리거나 아래로 파고드는 현상을 완벽 차단했습니다.
    - **Hacky한 여백 제거**: 스크롤 가동 범위 확보를 위해 사용했던 임시 공백들을 제거하고, `NestedScrollView` 아키텍처를 통해 목록 길이에 상관없는 범용적인 폴딩 시스템을 구축했습니다.
    - **시각적 완성도**: `BouncingScrollPhysics` 적용과 QR 코드 레이아웃 최적화로 네이티브 앱 수준의 고품질 UI를 달성했습니다.
- **UI/UX 정밀화**
    - `LobbyGameCodeCard`: `expandRatio`에 기반한 실시간 레이아웃 변형(높이, 투명도, 아이콘 회전, QR 스케일) 최적화
    - 부모 위젯의 `setState` 없이 `ScrollController`의 오프셋 변화에만 반응하여 깜빡임 없는 네이티브 수준의 스크롤 경험 제공

#### 📝 비고 / 특이사항
- **UX 향상**: 참여자 목록이 많을 때 화면 공간을 효율적으로 활용 가능
- **성능 최적화**: 
    - 카드 확장/축소 상태를 카드 위젯 내에서 자체적으로 관리하도록 리팩토링
    - 부모 위젯(`LobbyScreen`)의 `setState` 호출을 제거하여 화면 전체가 깜빡이는(리빌드되는) 현상 해결
    - 300ms 애니메이션 지속 시간과 `easeInOut` 커브로 부드러운 전환 제공

#### 🔗 관련 파일
- `lib/features/game/presentation/widgets/lobby_game_code_card.dart` - StatefulWidget 변환 및 애니메이션 구현
- `lib/features/game/presentation/lobby_screen.dart` - 스크롤 감지 로직 및 상태 관리 추가

---

### 🚀 기능 구현: 홈화면 아바타 클릭으로 프로필 수정 (Profile Edit from Home Avatar)

#### ✅ 주요 작업 및 성과
- **홈화면 프로필 클릭 시 수정 화면 진입 기능 구현**
    - `HomeProfileCard`: `onTap` 콜백 파라미터 추가 및 `GestureDetector`로 클릭 가능하게 변경
    - 아바타 우측 하단에 편집 아이콘 인디케이터 표시 (클릭 가능 시에만)
    - `HomeScreen`: 아바타 클릭 시 `/edit-profile` 경로로 이동하며 기존 닉네임/아바타 값을 `extra`로 전달
- **OnboardingScreen 수정 모드 지원 추가**
    - `isEditMode`, `initialNickname`, `initialAvatarSeed` 파라미터 추가
    - 수정 모드에서는 기존 값으로 닉네임/아바타 초기화
    - AppBar 타이틀: "프로필 수정" (수정 모드) / "프로필 설정" (신규)
    - 버튼 텍스트: "수정 완료" (수정 모드) / "설정 완료" (신규)
    - 뒤로가기: 수정 모드에서는 취소 다이얼로그 없이 바로 pop
    - 완료 시: 수정 모드에서는 홈으로 자동 복귀
- **Main Shell AppBar 중복 방지**
    - 수정 모드에서는 OnboardingScreen 자체 AppBar와 배경 제거
    - `appBarProvider`를 통해 Main Shell의 AppBar에 "프로필 수정" 타이틀 설정
- **라우터 `/edit-profile` 경로 추가**
    - Main Shell 내부에 배치하여 일관된 앱바와 배경 제공
    - `extra` 파라미터로 기존 프로필 값 전달

#### 📝 비고 / 특이사항
- **라우트 분리 이유**: 기존 `/onboarding` 경로는 프로필 미완성 사용자 전용 리다이렉트 로직이 있어 별도 경로로 분리
- **타입 오류 수정**: `state.extra`를 `Map<String, dynamic>`으로 캐스팅하여 런타임 오류 해결

#### 🔗 관련 파일
- `lib/features/home/widgets/home_profile_card.dart` - 클릭 이벤트 및 편집 아이콘 추가
- `lib/features/home/home_screen.dart` - 아바타 클릭 시 /edit-profile로 이동
- `lib/features/onboarding/onboarding_screen.dart` - 수정 모드 지원 추가
- `lib/core/router/app_router.dart` - /edit-profile 라우트 추가

---

## 2026-01-18 (일)
 
### 🚀 버그 수정: 다이얼로그 텍스트 밑줄 및 스타일 상속 이슈 해결 (HUD Dialog Text Style Fix)

#### ✅ 주요 작업 및 성과
- **다이얼로그 전역 Material 테마 적용**
    - `HudDialog`: 다이얼로그의 최상위 위젯을 `Material`로 감싸서 텍스트 스타일 상속 계층이 끊기는 문제 해결
    - **원인 해결**: `showGeneralDialog`를 통해 생성된 독립적인 위젯 트리에 `Material` 위젯이 없어 발생하는 Flutter의 기본 텍스트 밑줄(노란색 쌍줄) 현상 제거
- **디자인 일관성 유지**
    - `MaterialType.transparency`를 적용하여 기존의 글래스모피즘(유리 질감) 배경은 유지하면서 텍스트 스타일만 정상적으로 상속되도록 최적화

#### 📝 비고 / 특이사항
- **UX 개선**: 로그아웃 다이얼로그 등 모든 `HudDialog` 기반 알림창에서 텍스트가 깨지거나 밑줄이 생기는 문제를 해결하여 시인성 확보

#### 🔗 관련 파일
- `lib/core/widgets/hud_dialog.dart` - `Material` 위젯 도입 및 텍스트 스타일 보정

---
 
### 🚀 버그 수정: 도둑 플레이어 점수 마이너스 표시 오류 해결 (Robber Score Underflow Fix)
 
#### ✅ 주요 작업 및 성과
- **서버 시간 오프셋 보정 로직 통합**
    - `GameRepository`: 점수 산출 및 시간 계산이 필요한 주요 메소드(`finishGame`, `catchRobber`, `usePrisonKey`)에 `serverTimeOffset` 파라미터를 추가하고 이를 반영하도록 고도화
    - **시간 불일치 해결**: 기기 로컬 시간(`DateTime.now()`) 대신 추정 서버 시간(`getEstimatedServerTime`)을 사용하여 기기 간 시간 차이로 인한 데이터 왜곡 방지
- **생존 시간 계산 안전성 확보**
    - 도둑의 생존 시간(`addedSurvivalSec`) 계산 시 `max(0, ...)`를 적용하여, 클라이언트-서버 간 미세한 시간차나 설정 오류로 인해 점수가 음수가 되는 현상을 원천 차단
- **UI-Repository 간 데이터 동기화**
    - `PlayScreen`, `PrisonScreen`, `QrScanScreen`: 각 화면에서 계산된 서버 시간 오프셋을 Repository 호출 시 정확히 전달하도록 전체 호출부 수정
 
#### 📝 비고 / 특이사항
- **데이터 신뢰성 향상**: 기기 시간이 수동으로 잘못 설정된 환경에서도 게임 데이터(점수, 생존 시간)의 무결성을 보장할 수 있게 됨
- **로직 일관성**: 모든 핵심 게임 액션(체포, 탈출, 종료)에서 동일한 시간 보정 알고리즘을 사용하도록 표준화
 
#### 🔗 관련 파일
- `lib/features/game/data/game_repository.dart` - 서버 시간 오프셋 적용 및 음수 방지 로직
- `lib/features/game/presentation/play_screen.dart` - 오프셋 전달 로직 추가
- `lib/features/game/presentation/prison_screen.dart` - 오프셋 전달 로직 추가
- `lib/features/game/presentation/qr_scan_screen.dart` - 오프셋 전달 로직 추가
 
---
 

### 🚀 버그 수정: 감옥 수감 중 게임 종료 미작동 해결 (Prison Screen Game Finish Fix)

#### ✅ 주요 작업 및 성과
- **감옥 화면 내 종료 체크 로직 구현**
    - `PrisonScreen`: 방장(Host) 권한이 있는 사용자일 경우, 감옥 화면에서도 실시간으로 게임 종료 시간을 확인하고 `finishGame`을 트리거하도록 개선
    - **원인 해결**: 기존에 `PlayScreen`에만 존재하던 종료 로직을 감옥 화면으로 확장하여, 방장이 수감된 상태에서도 게임이 정상적으로 종료되도록 수정
- **타이머 연동 고도화**
    - `_startTimer` 주기 내에 종료 조건 검사(`_checkEndConditions`)를 포함시켜 시간 지연 없는 즉각적인 상태 전환 보장

#### 📝 비고 / 특이사항
- **UX 신뢰도 향상**: 남은 시간이 00:00임에도 게임이 계속 진행되어 결과 화면을 보지 못하던 심각한 버그를 해결하여 게임의 정체성 회복

#### 🔗 관련 파일
- `lib/features/game/presentation/prison_screen.dart` - `_checkEndConditions` 추가 및 타이머 연동

---

### 🚀 아키텍처 개선: 분산 게임 종료 시스템 구축 (Decentralized Game Finish System)

#### ✅ 주요 작업 및 성과
- **방장 의존성 제거 및 분산 검증 로직 구현**
    - 기존 방장(Host) 1인에게 의존하던 종료 로직을 모든 참가자가 참여하는 구조로 전면 개편
    - **Smart Jitter 적용**: 클라이언트별 0~3초 랜덤 지연을 통해 동시 요청 부하(Thundering Herd) 현상 방지
- **Firestore 트랜잭션 최적화 및 멱등성 확보**
    - `GameRepository.finishGame`: 트랜잭션 진입 전 상태 선행 체크(First-order Check)와 트랜잭션 내 원자적 재검증(Atomic Verifier)을 결합하여 최초 1인만 성공하도록 보장
- **UI 연동 및 예외 처리 강화**
    - `PlayScreen`, `PrisonScreen`: 방장 여부와 상관없이 모든 기기에서 종료 조건을 감시하도록 수정
    - 트랜잭션 충돌 시 발생하는 예외를 안전하게 처리하여 사용자 화면에 영향이 없도록 조치

#### 📝 비고 / 특이사항
- **신뢰성 확보**: 방장이 게임 중 앱을 강제 종료하거나 네트워크가 유실되더라도 다른 참가자 중 1명이라도 앱이 켜져 있으면 게임이 정상 종료됨
- **전문적 최적화**: 트랜잭션 충돌을 방어하기 위한 Jitter 기법을 도입하여 서버 부하 걱정 없는 대안 제시

#### 🔗 관련 파일
- `lib/features/game/data/game_repository.dart` - 멱등성 트랜잭션 구현
- `lib/features/game/presentation/play_screen.dart` - 분산 체크 및 Jitter 적용
- `lib/features/game/presentation/prison_screen.dart` - 분산 체크 및 Jitter 적용

---

---

### 🚀 버그 수정: 화면 전환 시 QR 다이얼로그 잔상 제거 (QR Dialog Persistence Fix)

#### ✅ 주요 작업 및 성과
- **다이얼로그 상태 추적 및 강제 종료 로직 구현**
    - `PlayScreen`, `PrisonScreen`: 다이얼로그의 열림 상태를 추적하는 `_isDialogOpen` 변수 추가
    - **안전한 화면 전환**: 도둑이 체포되어 수감 화면으로 넘어가거나, 석방되어 플레이 화면으로 복귀할 때 열려 있는 다이얼로그(`rootNavigator`)를 먼저 닫은 후 이동(`context.go`)하도록 개선
- **다이얼로그 생명주기 관리 최적화**
    - `HudDialog.show().then(...)` 및 "닫기" 버튼의 콜백을 통해 다이얼로그가 닫힐 때 상태 변수가 정확히 업데이트되도록 보정
    - `rootNavigator` 스택을 확인하여 존재할 때만 `pop`을 호출하도록 방어 로직 강화

#### 📝 비고 / 특이사항
- **UX 개선**: 화면이 전환되었음에도 이전 화면의 다이얼로그가 남아 상호작용을 방해하고 뒤로가기를 두 번 해야 했던 불편함을 해소
- **구조적 해결**: 다이얼로그가 `rootNavigator`에 위치하여 화면 이동(`context.go`) 시 자동으로 닫히지 않던 엔진 특성을 고려한 명시적 종료 처리 적용

#### 🔗 관련 파일
- `lib/features/game/presentation/play_screen.dart` - 다이얼로그 추적 및 전환 로직 수정
- `lib/features/game/presentation/prison_screen.dart` - 다이얼로그 추적 및 복귀 로직 수정

---


### 🚀 기능 구현: 게임 활동 로그 확인 시스템 구축 (Activity Log Monitoring System)

#### ✅ 주요 작업 및 성과
- **전역 이벤트 모니터링 스트림 구현**
    - `GameRepository`: `watchAllEvents(String gameId)` 메소드를 추가하여 해당 게임의 모든 기록을 최신순으로 실시간 감시 가능하도록 고도화
- **플레이 및 결과 화면 UI 통합**
    - **PlayScreen**: 인원수 통계 섹션 하단에 "활동 로그 확인" 버튼을 추가하여 플레이 중 실시간 상황 복기 가능
    - **ResultScreen**: 최종 순위표 하단에 동일한 버튼을 배치하여 게임 종료 후 전체 타임라인 확인 지원
- **사용자 중심 로그 다이얼로그 구현**
    - `ActivityLogDialogContent`: 발생 시간([HH:mm:ss])과 활동 메시지를 가독성 있게 표시하는 전용 로그 뷰어 구축
    - 리스트가 길어질 경우를 대비한 스크롤 및 최대 높이 제한 적용

#### 📝 비고 / 특이사항
- **코드 재사용성**: 하나의 로그 위젯(`ActivityLogDialogContent`)을 플레이 화면과 결과 화면에서 공유하여 유지보수 효율 극대화
- **UX 가독성**: 결과 화면에서는 '영웅들의 발자취'라는 서사적인 타이틀을 적용하여 게임 마무리 경험 향상

#### 🔗 관련 파일
- `lib/features/game/data/game_repository.dart` - `watchAllEvents` 스트림 추가
- `lib/features/game/presentation/play_screen.dart` - 활동 로그 다이얼로그 연동
- `lib/features/game/presentation/result_screen.dart` - 결과 화면 내 로그 확인 버튼 추가
- `lib/features/game/presentation/widgets/play_widgets.dart` - `ActivityLogDialogContent` 위젯 구현

---

### 🚀 UX 개선: Prison Screen 하단 잘림 현상 해결 (스크롤 추가 및 레이아웃 최적화)

#### ✅ 주요 작업 및 성과
- **`PrisonScreen` 스크롤 기능 추가**: 화면 내용이 기기 높이를 초과할 경우 하단 UI 요소가 잘리는 문제를 해결하기 위해 `SingleChildScrollView`를 적용
- **레이아웃 최적화**: `SafeArea` 및 `Expanded` 위젯을 활용하여 다양한 화면 크기 및 노치 디자인에 대응하도록 UI 구성 요소를 재배치
- **일관된 디자인 유지**: 기존 `PrisonScreen`의 사이버펑크 테마와 `HudDialog` 스타일을 유지하면서 스크롤 기능을 통합

#### 📝 비고 / 특이사항
- **사용자 경험 향상**: 특정 기기에서 발생하던 UI 잘림 현상을 해결하여 모든 사용자가 원활하게 게임을 플레이할 수 있도록 개선
- **반응형 UI 강화**: 향후 다양한 해상도의 기기에서도 안정적인 화면을 제공할 수 있는 기반 마련

#### 🔗 관련 파일
- `lib/features/game/presentation/prison_screen.dart` - `SingleChildScrollView` 및 레이아웃 최적화

---

### 🚀 UX 개선: 게임 진행 중 뒤로가기 종료 확인 다이얼로그 안정화 (Game Shell Back Navigation Fix)

#### ✅ 주요 작업 및 성과
- **Game Shell 전역 뒤로가기 제어 시스템 구축**
    - `GameShellWrapper`: 게임 플레이 관련 모든 화면(`PlayScreen`, `PrisonScreen`, `QrScanScreen`)을 감싸는 쉘 레벨에 `PopScope`를 적용하여 시스템 뒤로가기 이벤트를 일관되게 가로채도록 개선
    - **종료 확인 다이얼로그 통합**: 뒤로가기 발생 시 "정말 게임에서 나가시겠습니까?" 다이얼로그를 표시하고, 사용자 승인 시에만 홈 화면으로 이동하도록 로직 통합
- **구조적 버그 원인 파악 및 코드 정돈**
    - **원인 분석**: `PlayScreen`이 `GameShellNavigator`의 루트(첫 번째) 화면일 경우, 개별 `PopScope`가 Navigator의 스택 판단 로직에 의해 무시될 수 있는 현상 확인 및 해결
    - **중복 제거**: `PlayScreen` 내부에 개별적으로 구현되었던 다이얼로그 로직 및 `PopScope`를 제거하여 코드 유지보수성 향상

#### 📝 비고 / 특이사항
- **UX 신뢰도 향상**: 기존에 일부 상황에서 뒤로가기 시 앱이 즉시 종료되던 문제를 구조적으로 해결하여 사용자 피드백 반영
- **확장성**: 향후 게임 쉘 내에 새로운 화면이 추가되더라도 별도의 설정 없이 뒤로가기 방지 로직이 즉시 적용되는 구조 확보

#### 🔗 관련 파일
- `lib/core/router/game_shell_wrapper.dart` - 전역 `PopScope` 및 종료 다이얼로그 구현
- `lib/features/game/presentation/play_screen.dart` - 중복 로직 제거 및 코드 정리

---

## 2026-01-15 (목)

### 🚀 기능 구현: NFC 보안 열쇠 고도화 및 딥링크 연동 (NFC Security Key & Deep Link Integration)

#### ✅ 주요 작업 및 성과
- **NFC 기반 앱 런칭 및 자동 참여 시스템 구축**
    - **Android App Links 설정**: `AndroidManifest.xml`에 `catchrun.app/join` 도메인에 대한 인텐트 필터 및 `autoVerify=true` 설정 추가
    - **NDEF URI 및 AAR 쓰기**: `LobbyScreen`에서 NFC 태그 기록 시, 특정 게임 참여를 위한 URI(`https://catchrun.app/join?...`)와 안드로이드 앱 자동 실행을 위한 AAR(Android Application Record)을 함께 기록하도록 고도화
    - **Deep Link 라우팅 구현**: `app_router.dart`에 `/join` 경로 추가 및 쿼리 파라미터(`gameId`, `nfcKeyId`)를 로비(`/lobby/:gameId`)로 전달하는 리다이렉트 로직 구현
- **로비 자동 참여 로직 구현**
    - `LobbyScreen`: 딥링크를 통해 진입 시 `nfcKeyId`를 감지하고, 사용자 프로필 로딩 완료 시점에 맞춰 `joinGameByNfcKey`를 트리거하는 자동 참여 프로세스 구축
- **감옥 탈출 로직 고도화**
    - `PrisonScreen`: NFC 태그에서 URI 레코드를 직접 파싱하여 `nfcKeyId`를 추출해 탈출 트랜잭션에 활용하도록 수정
- **코드 안정성 및 품질 확보**
    - `nfc_manager` 패키지의 파괴적 변경에 대응하여 `NdefRecord` 수동 생성 방식으로 전환(`createUri`, `createExternal` 오류 해결)
    - `flutter analyze` 정적 분석 전수 통과 (Exit code: 0)

#### 📝 비고 / 특이사항
- **네비게이션 이슈**: 앱 런칭은 정상 동작하나, 특정 상황에서 리다이렉트 로직이 `/home`으로 덮어씌워지는 문제 발견 및 수정 진행 중 (`app_router.dart` 내 글로벌 리다이렉트 조건 완화)
- **메시지 통일**: NFC를 통한 입장 메시지를 기존의 코드/QR 입장 메시지 양식과 동일하게 통일하여 UX 일관성 유지

#### 🔗 관련 파일
- `lib/core/router/app_router.dart` - `/join` 라우트 및 리다이렉트 로직 수정
- `lib/features/game/presentation/lobby_screen.dart` - NFC 쓰기(URI+AAR) 및 자동 참여 리스너 추가
- `lib/features/game/presentation/prison_screen.dart` - URI 기반 NFC 읽기 로직 수정
- `lib/features/game/presentation/prison_screen.dart` - URI 기반 NFC 읽기 로직 수정
- `lib/features/game/data/game_repository.dart` - `joinGameByNfcKey` 메서드 추가
- `android/app/src/main/AndroidManifest.xml` - App Links 설정 추가

---

## 2026-01-14 (수)

### 🚀 기능 구현: 글로벌 네트워크 연결 체크 및 예외 처리 (Global Network Connectivity Check)

#### ✅ 주요 작업 및 성과
- **애플리케이션 전역 네트워크 모니터링 시스템 구축**
    - `connectivity_plus` 패키지를 활용하여 기기의 인터넷 연결 상태를 실시간으로 감시하는 `ConnectivityService` 구현
    - 모든 주요 네트워크 요청 전 `ensureConnection()` 호출을 강제하여 오프라인 상태에서의 불필요한 대기 방지
- **사이버펑크 테마의 전역 안내 다이얼로그(`NetworkErrorDialog`) 구현**
    - 연결 끊김 시 사용자에게 알림을 제공하고 "설정" 버튼을 통해 기기의 Wi-Fi 설정 화면으로 즉시 이동 가능하도록 구현
    - `GoRouter`의 `rootNavigatorKey`를 활용하여 앱의 어떤 화면에서도 다이얼로그를 띄울 수 있도록 설계
- **리포지토리 및 컨트롤러 계층 통합**
    - `AuthRepository`, `UserRepository`, `GameRepository`의 모든 데이터 통신 로직에 연결 확인 절차 통합
    - `NetworkErrorHandler`를 통해 비동기 작업 중 발생하는 네트워크 예외를 포괄적으로 잡고 사용자에게 시각적 피드백 제공
- **안정성 및 디버깅**
    - `flutter analyze`를 통한 정적 분석 및 컴파일 에러(누락된 임포트, 필드 등) 전수 수정
    - 오프라인 상태에서 로그아웃 시 반응이 없던 버그 해결 및 서버 시간 동기화 로직 보완

#### 📝 비고 / 특이사항
- **UX 일관성**: 단순한 시스템 경고창 대신 앱의 SF 테마와 일치하는 `HudDialog` 기반 디자인을 적용하여 몰입감 유지
- **최신 API 대응**: `connectivity_plus` v6의 리스트 반환 방식을 고려한 견고한 연결 판별 로직 적용
- **문제 해결**: 구현 과정에서 발생한 `AuthRepository` 필드 누락 및 `SciFiButton` 오타 등 휴먼 에러를 전면 수정하여 빌드 안정성 확보

#### 🔗 관련 문서
- [implementation_plan.md](brain/17ab7a78-fd16-4cae-a839-2bbece995b13/implementation_plan.md)
- [walkthrough.md](brain/17ab7a78-fd16-4cae-a839-2bbece995b13/walkthrough.md)

---

## 2026-01-13 (화)

### 🚀 UX 개선: 프로필 설정 취소 시 익명 계정 자동 삭제 및 로그아웃 구현 (Anonymous Account Deletion on Cancel)

#### ✅ 주요 작업 및 성과
- **보안 및 데이터 정화: 익명 계정 삭제 프로세스 통합 및 확장**
    - 프로필 설정 단계뿐만 아니라, 홈 화면에서 로그아웃할 때도 익명 계정인 경우 자동으로 데이터를 정화하도록 로직 확장
    - `AuthController.signOut()`: 익명 계정 여부를 확인하여 데이터 및 계정 삭제를 수행하도록 로직 통합
- **이탈 방지 확인 다이얼로그 문구 보안**
    - `HomeScreen` 및 `OnboardingScreen`: 로그아웃/취소 시 "익명 계정인 경우 모든 데이터가 삭제됩니다." 안내 문구 추가로 사용자 인지 강화

#### 📝 비고 / 특이사항
- **개인정보 보호**: 프로필이 완성되지 않은 유령 계정이 DB에 쌓이는 것을 방지하여 데이터 품질 및 개인정보 관리 효율성 향상
- **라우팅 자동화**: 별도의 `context.go` 호출 없이 `authStateChangesProvider`의 상태 변화를 감지하여 `app_router.dart`의 리다이렉션 로직이 자연스럽게 동작하도록 설계

#### 🔗 관련 파일
- `lib/core/auth/auth_repository.dart` - 익명 계정 삭제 메서드 추가
- `lib/core/user/user_repository.dart` - 익명 데이터 삭제 메서드 추가
- `lib/features/auth/auth_controller.dart` - `cancelRegistration` 통합 로직 구현
- `lib/features/onboarding/onboarding_screen.dart` - `PopScope` 및 확인 다이얼로그 적용

---

### 🚀 UX 개선: 홈 및 로그인 화면 뒤로가기 종료 확인 다이얼로그 구현 (Back Navigation Exit Dialog)

#### ✅ 주요 작업 및 성과
- **앱 종료 확인 프로세스 도입**
    - 홈 화면 및 로그인 화면에서 실수로 뒤로가기를 눌러 앱이 즉시 종료되는 문제를 방지하기 위해 `PopScope`를 활용한 확인 다이얼로그 구현
    - `HudDialog.show()`를 사용하여 "캐치런을 종료하시겠습니까?" 메시지 표시 및 '취소', '종료' 버튼 제공
- **ShellRoute 내 PopScope 동작 버그 수정**
    - **문제**: `ShellRoute` 내부 화면인 `HomeScreen`에 직접 `PopScope`를 적용했을 때, 상위 Navigator에 의해 이벤트가 무시되어 다이얼로그 없이 앱이 종료되는 현상 발견
    - **해결**: 공통 래퍼인 `MainShellWrapper`에 `PopScope`를 이동 적용하고, `GoRouterState`를 통해 현재 경로가 `/home`인 경우에만 종료 확인 로직이 동작하도록 최적화
- **정적 분석 및 코드 건강도 개선**
    - `HomeScreen`에서 중복된 `PopScope` 및 헬퍼 메서드 제거
    - 사용하지 않는 `flutter/services.dart` 임포트 정리 및 `flutter analyze` 통과

#### 📝 비고 / 특이사항
- **일관된 UX**: 로그인 화면(독립 경로)과 홈 화면(쉘 경로) 모두에서 동일한 스타일의 종료 확인 창을 제공하여 사용자 경험의 일관성 확보
- **라우팅 최적화**: 쉘 레벨에서 경로를 판별하여 이벤트를 제어함으로써 향후 다른 쉘 내부 화면으로의 확장이 용이한 구조 확보

#### 🔗 관련 파일
- `lib/core/router/main_shell_wrapper.dart` - 공통 `PopScope` 적용 및 종료 로직 통합
- `lib/features/home/home_screen.dart` - 중복 로직 제거 및 코드 정리
- `lib/features/auth/login_screen.dart` - 독립적인 `PopScope` 적용

---

### 🚀 UX 개선: 결과 화면 뒤로가기 동작 수정 (Result Screen Back Navigation Fix)

#### ✅ 주요 작업 및 성과
- **뒤로가기 가로채기 및 리다이렉션 구현**
    - `ResultScreen`: `PopScope`를 도입하여 시스템 뒤로가기 버튼 클릭 시 앱이 종료되는 대신 홈 화면(`/home`)으로 이동하도록 수정
    - **네비게이션 제어**: `canPop: false` 설정 및 `onPopInvokedWithResult`에서 `context.go('/home')` 호출
- **UI 정리**
    - `AppBar`: `automaticallyImplyLeading: false`를 설정하여 불필요한 기본 뒤로가기 아이콘 제거

#### 📝 비고 / 특이사항
- **UX 개선**: 게임 종료 후 결과 화면이 스택의 최상위일 때 뒤로가기로 우발적인 앱 종료가 발생하는 문제를 방지하고 자연스럽게 홈으로 유도함

#### 🔗 관련 파일
- `lib/features/game/presentation/result_screen.dart` - `PopScope` 적용 및 앱바 수정

---


### � 버그 수정: 게임 시작 시 타이머 동기화 문제 해결 (Game Timer Synchronization Fix)

#### ✅ 주요 작업 및 성과
- **문제 원인 분석 및 해결**
    - **문제 현상**: 게임 시작 시 타이머가 정상 동작하지 않거나 다른 기기와 시간이 맞지 않는 문제 발생
    - **근본 원인**: `startGame()` 메서드에서 `endsAt`를 **호스트 클라이언트의 로컬 시간** 기준으로 계산하여 저장
        - 서버 타임스탬프(`startedAt`)와 클라이언트 시간(`endsAt`)이 혼용되어 기기 간 시간 불일치 발생
- **서버 시간 기반 타이머 계산으로 전환**
    - `PlayScreen`: `endsAt` 대신 **`startedAt + durationSec`** 을 사용하여 종료 시간 계산
        - 기존: `game.endsAt!.difference(estimatedServerTime)`
        - 변경: `game.startedAt!.add(Duration(seconds: game.durationSec)).difference(estimatedServerTime)`
    - `PrisonScreen`: 동일한 로직 적용으로 감옥 화면에서도 정확한 타이머 표시
    - `_checkEndConditions()`: 게임 종료 조건 검사 시에도 서버 시간 기반으로 일관성 유지

#### 📝 비고 / 특이사항
- **기술적 이유**: `startedAt`은 Firestore 서버 타임스탬프(`FieldValue.serverTimestamp()`)로 저장되어 모든 클라이언트에서 동일한 값을 갖지만, `endsAt`는 호스트의 로컬 시간으로 계산되어 불일치 발생
- **서버 시간 offset**: 기존에 구현되어 있던 `_serverTimeOffset`을 활용하여 정확한 남은 시간 계산

#### 🔗 관련 파일
- `lib/features/game/presentation/play_screen.dart` - 남은 시간 계산 및 게임 종료 조건 로직 수정
- `lib/features/game/presentation/prison_screen.dart` - 남은 시간 계산 로직 수정

---

### �🛠️ 앱바 통합 및 레이아웃 개선 (Unified AppBar & Layout Refinement)

#### ✅ 주요 작업 및 성과
- **통합 앱바 시스템 구축**
    - `AppBarConfig`: `leading` 속성 추가로 화면별 커스텀 뒤로가기 동작 지원
    - `MainShellWrapper` / `GameShellWrapper`: `appBarProvider`를 통한 중앙 집중식 앱바 관리
    - `GoRouter` 기반 뒤로가기 버튼: `context.canPop()` / `context.pop()` 패턴 적용
- **화면별 레이아웃 개선**
    - `JoinGameScreen`: `TabBar`를 화면 본문에 직접 통합하여 앱바와 겹침 문제 해결
    - `LobbyScreen`: 커스텀 `leading` 버튼으로 뒤로가기 시 나가기 확인 다이얼로그 표시 후 홈 이동
    - `CreateGameScreen`: 로비 이동 시 `context.go` → `context.push`로 변경하여 네비게이션 스택 유지

#### ✅ 버그 수정 및 안정성 강화
- **컴파일 에러 해결**
    - `LobbyScreen`: `NdefRecord`, `TypeNameFormat` 임포트 누락 수정 (`nfc_manager/ndef_record.dart`)
    - `PrisonScreen`: NFC `pollingOptions` 필수 파라미터 추가
    - `Share` API: deprecated `shareWithResult` → `share` 복원
    - `NdefMessage` / `ndef.write`: 명명된 파라미터 형식 수정 (`records:`, `message:`)
- **비동기 갭 안전성 강화**
    - NFC 콜백 내 `Navigator` 및 `ScaffoldMessenger`를 미리 캡처하여 `mounted` 체크 후 안전하게 사용
    - `_handleExit()`: 다이얼로그 표시 전 `mounted` 체크 및 `rootNavigator` 캡처로 위젯 언마운트 오류 방지

#### 📝 비고 / 특이사항
- **린트 상태**: `flutter analyze` 기준 에러/경고 0건. 남은 이슈는 `info` 레벨(deprecated API 권고, 비동기 갭 린트)로 앱 동작에 영향 없음
- **아키텍처 개선**: `extendBodyBehindAppBar: true` 환경에서 각 화면이 `MediaQuery.of(context).padding.top + kToolbarHeight`로 정확한 상단 여백을 계산하도록 통일

#### 🔗 관련 파일
- `lib/core/router/main_shell_wrapper.dart` - 통합 앱바 및 뒤로가기 버튼
- `lib/core/router/game_shell_wrapper.dart` - 게임 화면용 쉘 래퍼
- `lib/core/providers/app_bar_provider.dart` - `leading` 속성 추가
- `lib/features/game/presentation/lobby_screen.dart` - 커스텀 뒤로가기, NFC API 수정
- `lib/features/game/presentation/join_game_screen.dart` - TabBar 통합, 레이아웃 수정
- `lib/features/game/presentation/prison_screen.dart` - NFC 폴링 옵션 추가

---

### 🚀 앱바 타이틀 동적 업데이트 시스템 구축 (Dynamic AppBar Title Management)

#### ✅ 주요 작업 및 성과
- **RouteAware 기반 화면 전환 감지 시스템 구현**
    - `app_router.dart`: 각 ShellRoute에 별도의 `RouteObserver` 인스턴스 생성
        - `mainShellRouteObserverProvider`: Main Shell(Home, Create, Join, Lobby) 전용
        - `gameShellRouteObserverProvider`: Game Shell(Play, Prison, QrScan) 전용
    - 각 ShellRoute에 `observers` 파라미터로 해당 observer 등록
- **화면별 RouteAware mixin 적용**
    - `HomeScreen`, `CreateGameScreen`, `JoinGameScreen`에 `RouteAware` mixin 적용
    - `didChangeDependencies()`: RouteObserver 구독 설정
    - `didPopNext()`: 다른 화면에서 돌아올 때 앱바 업데이트
    - `dispose()`: RouteObserver 구독 해제
- **Riverpod Provider 빌드 중 수정 오류 해결**
    - `didPopNext()`에서 직접 provider 수정 시 "Tried to modify a provider while the widget tree was building" 에러 발생
    - 해결: `WidgetsBinding.instance.addPostFrameCallback()`으로 감싸서 빌드 완료 후 실행되도록 수정
- **앱바 설정 로직 `initState()`로 이동**
    - 기존 `build()` 내 `addPostFrameCallback` 호출을 `initState()`로 이동
    - 화면 최초 생성 시 한 번만 앱바 설정, 복귀 시에는 `didPopNext()`에서 처리

#### 📝 비고 / 특이사항
- **RouteObserver 중복 등록 에러**: 동일한 `RouteObserver` 인스턴스를 여러 Navigator(root, shell)에 등록할 수 없어 에러 발생. 각 Shell에 별도의 observer 인스턴스를 생성하여 해결.
- **ShellRoute 내부 push/pop 감지**: root Navigator의 observer는 ShellRoute 내부의 화면 전환을 감지하지 못함. ShellRoute의 `observers` 파라미터에 등록해야 내부 이동 감지 가능.
- **코드 패턴 정립**: 화면 전환 시 앱바 업데이트를 위한 정석적인 Flutter 패턴(RouteAware + addPostFrameCallback) 적용

#### 🔗 관련 파일
- `lib/core/router/app_router.dart` - RouteObserver 프로바이더 및 ShellRoute observers 설정
- `lib/features/home/home_screen.dart` - RouteAware mixin 적용
- `lib/features/game/presentation/create_game_screen.dart` - RouteAware mixin 적용
- `lib/features/game/presentation/join_game_screen.dart` - RouteAware mixin 적용

## 2026-01-12 (월)

### 🚀 UX 개선: 프로필 아바타 랜덤 생성 및 시각적 고도화 (Avatar Randomization & Visual Polish)

#### ✅ 주요 작업 및 성과
- **아바타 랜덤 생성 시스템 구축**
    - `OnboardingScreen`: 4종의 캐릭터 이미지(`profile1~4.png`) 중 하나를 무작위로 선택하는 로직 구현
    - `dart:math`의 `Random` 클래스를 활용하여 버튼 클릭 시 현재와 다른 이미지가 선택되도록 정밀도 향상
    - 초기 진입 시 항상 `profile1.png`가 표시되도록 요구사항 반영
- **아바타 시각적 완성도 향상**
    - `GlassAvatar`, `HomeProfileCard`: 글래스모피즘 원형 프레임 내에 아바타가 꽉 차게 표시되도록 `BoxFit.cover` 적용
    - 이미지 로딩 오류 발생 시 펄백(Fallback) 아이콘(👤)을 표시하여 앱의 안정성 및 시인성 확보
- **정적 분석 및 코드 건강도 개선**
    - `flutter analyze` 수행 후 발견된 미사용 임포트(`uuid.dart`) 및 중복 명명된 인자(`alignment`) 제거
    - `UserModel` 내 기존 `avatarSeed` 필드를 적극 활용하여 설정값이 유실되지 않도록 연동

#### 📝 비고 / 특이사항
- **디자인 일관성**: 온보딩 단계에서 선택한 아바타가 홈 화면의 프로필 카드에 즉시 반영되어 개인화된 사용자 경험(UX) 제공
- **안정성**: `Image.asset`의 `errorBuilder`를 사용하여 에셋 누락 상황에서도 사용자 인터페이스가 무너지지 않도록 설계

#### 🔗 관련 문서
- [walkthrough.md](C:\Users\voll1\.gemini\antigravity\brain\e3b6e15b-0b73-42eb-bc88-26eb34bf2cbc\walkthrough.md)

---

### 🚀 UX 개선: 게임 생성 화면 인원 선택 방식 고도화 (Create Game Spinner & Touch Area Expansion)

#### ✅ 주요 작업 및 성과
- **인원 선택용 스피너(CupertinoPicker) 도입**
    - `CreateGameScreen`: 경찰 및 도둑 인원 숫자를 클릭하면 하단 바텀 시트에 iOS 스타일의 `CupertinoPicker`가 나타나 1~99 사이의 숫자를 직관적으로 선택할 수 있도록 개선
- **위젯 확장성 강화**
    - `ParticipantCounter`: 숫자를 클릭할 수 있는 `onCountPressed` 콜백 필드 추가 및 `GestureDetector` 구현
- **터치 영역 및 UX 최적화**
    - 모바일 환경의 조작 편의성을 위해 숫자 양옆의 빈 공간(버튼 이전까지)을 모두 터치 영역으로 확장 (`Expanded` 및 `HitTestBehavior.opaque` 활용)
    - 기존의 +, - 버튼 방식과 스피너 선택 방식을 병행 제공하여 사용자 선택폭 확대

#### 📝 비고 / 특이사항
- **조작성 향상**: 작은 숫자를 직접 터치하기 어려운 환경을 고려하여 터치 영역을 최대화함으로써 오동작 줄이고 사용성 개선
- **디자인 일관성**: HUD 테마에 어울리는 어두운 배경의 바텀 시트와 민트색 '확인' 버튼을 사용하여 시디컬 미학 유지

#### 🔗 관련 문서
- 수정 파일:
    - `lib/core/widgets/counter_button.dart` - `ParticipantCounter` 터치 영역 확장 및 콜백 추가
    - `lib/features/game/presentation/create_game_screen.dart` - `CupertinoPicker` 기반 선택 로직 구현

---

## 2026-01-11 (일)

### 🧹 코드 품질 개선: 위젯 분리 및 HUD 공통화 (Widget Separation & HUD Standardization)

#### ✅ 주요 작업 및 성과
- **공통 위젯 시스템 구축**
    - `lib/core/widgets/stat_item.dart`: 통계 표시용 범용 위젯 추출 및 파라미터 표준화 (`color` -> `valueColor`)
    - `lib/core/widgets/hud_dialog.dart`: 앱 전반의 다이얼로그 디자인 통일을 위한 `HudDialog` 구현 및 `static show()` 메서드 제공
    - `lib/core/widgets/glass_container.dart`: 외부 레이아웃 제어를 위한 `margin` 파라미터 추가
- **화면별 위젯 분리 및 리팩토링**
    - `home_screen.dart`: `HomeProfileCard` 추출
    - `lobby_screen.dart`: `LobbyGameCodeCard`, `LobbyParticipantTile` 추출
    - `play_screen.dart`: `MyQrDialogContent` (`play_widgets.dart`) 추출
    - `result_screen.dart`: `ResultTitleCard`, `ResultRankingItem` (`result_widgets.dart`) 추출
    - **결과**: 모든 화면(`Home`, `Lobby`, `Play`, `Prison`, `Result`, `Join`)이 통일된 `HudDialog` 및 분리된 위젯을 사용하도록 구조 개선
- **다이얼로그 시스템 전면 교체**
    - 기존의 복잡하고 중복된 `showGeneralDialog` 호출을 `HudDialog.show()`로 대체하여 가독성 향상 및 디자인 일관성 확보

#### 📝 비고 / 특이사항
- **디자인 시스템 일관성**: 모든 알림과 확인 창이 동일한 글래스모피즘 HUD 테마를 따르게 되어 사용자 인터페이스의 전문성 향상
- **유지보수성**: 각 화면 파일의 크기가 대폭 줄어들었으며(최대 30% 이상), UI 컴포넌트 수정 시 관련 위젯 파일만 수정하면 모든 화면에 반영됨

#### 🔗 관련 문서
- `C:\Users\voll1\.gemini\antigravity\brain\215809b8-4b98-4af3-baba-c726fb4ee2a8\walkthrough.md`

---

### 🧹 코드 품질 개선: 린트 오류 수정 및 비동기 처리 표준화 (Lint Fix & BuildContext Standardization)

#### ✅ 주요 작업 및 성과
- **프로젝트 전수 린트 정화**
    - `flutter analyze` 결과 확인된 모든 오류 및 경고 해결
    - 미사용 임포트(`qr_flutter`, `go_router`) 제거 및 누락된 임포트 보충
    - 정확한 파라미터 매핑을 통해 정의되지 않은 명명된 파라미터 오류 해결
- **비동기 BuildContext 안전 처리 표준화**
    - `use_build_context_synchronously` 경고를 방지하기 위한 전수 보안 패치
    - **주요 수정 패턴**:
        - `await` 이전에 `Navigator.of(context)` 또는 `ScaffoldMessenger.of(context)`를 변수에 캡처하여 사용
        - 비동기 작업 후 반드시 `if (mounted)` 또는 `if (context.mounted)` 체크 수행
    - **적용 대상**: `LobbyScreen`, `QrScanScreen`, `PrisonScreen`, `JoinGameScreen` 등 비즈니스 로직이 밀집된 모든 화면
- **최종 검증**
    - `flutter analyze` 실행 결과 **No issues found!** 상태 달성 및 유지

#### 📝 비고 / 특이사항
- **런타임 안정성**: 비동기 작업 중 화면이 닫히는 예외 상황에서도 앱이 비정상적으로 종료되지 않도록 방어 로직 강화
- **코드 품질**: 단순 수정을 넘어 전체 코드베이스에 걸쳐 일관된 비동기 처리 패턴을 확립함

#### 🔗 관련 문서
- `C:\Users\voll1\.gemini\antigravity\brain\215809b8-4b98-4af3-baba-c726fb4ee2a8\walkthrough.md`

---

### 🚀 기능 추가 및 UX 개선: 참여자 강퇴 및 로비 보직 변경 (Kick Participant & Lobby UX)

#### ✅ 주요 작업 및 성과
- **참여자 강퇴(Kick) 기능 구현**
    - `GameRepository.kickParticipant()`: 특정 참여자를 게임에서 제거하는 트랜잭션 로직 추가
    - `LobbyScreen`: 방장이 참여자 클릭 시 나타나는 관리 메뉴에 "강퇴하기" 옵션 추가
    - **강퇴 알림 시스템**: 
        - 강퇴당한 유저가 자동으로 홈 화면으로 이동하며 안내 다이얼로그를 받도록 구현
        - `HomeScreen`에서 `isKicked` 파라미터를 감지하여 신뢰성 있는 알림 표시 (`didUpdateWidget` 활용)
- **로비 UX 스트림라인 (방장 본인 보직 변경)**
    - **기존 문제**: 방장이 본인 보직을 변경하려면 불필요한 중간 메뉴를 거쳐야 했음
    - **개선**: `LobbyScreen`에서 방장이 본인 프로필 클릭 시 즉시 역할 변경 바텀시트가 노출되도록 직관적으로 변경
- **코드 품질 및 UI 안정화**
    - `HomeScreen`: 중복 정의된 로컬 위젯(`_HudText`, `_SciFiButton`)을 제거하고 공통 위젯(`HudText`, `SciFiButton`)으로 통합
    - `HomeScreen`: 누락되었던 `dart:ui` 임포트를 복구하여 `ImageFilter` 오류 해결
    - `LobbyScreen`: 스트림 구독(`StreamSubscription`) 방식을 도입하여 강퇴 여부를 실시간으로 더욱 견고하게 감시

#### 📝 비고 / 특이사항
- **강퇴 로직의 안정성**: 단순 팝업이 아니라 리포지토리 레이어에서 데이터를 삭제하고, 클라이언트가 이를 감지하여 정중하게 퇴장시키는 프로세스를 구축함
- **UI 일관성**: 홈 화면의 레거시 위젯들을 공통 위젯으로 교체함으로써 앱 전반의 디자인 시스템 일관성 확보
- **버그 해결**: `GoRouterState`의 비정상적인 상태 읽기로 인해 강퇴 알림이 안 뜨던 이슈를 `GoRouter` 파라미터와 생성자 주입 방식으로 개선하여 해결

#### 🔗 관련 문서
- 수정 파일:
    - `lib/features/game/presentation/lobby_screen.dart` - 강퇴 메뉴 및 본인 역할 변경 로직
    - `lib/features/game/data/game_repository.dart` - 강퇴 트랜잭션 구현
    - `lib/features/home/home_screen.dart` - 위젯 통합 및 강퇴 알림 처리
    - `lib/core/router/app_router.dart` - 강퇴 파라미터 라우팅 설정

---


### ⚖️ 게임 밸런스 개선: 열쇠 사용 점수 차감 구현 (Prison Key Score Penalty)

#### ✅ 주요 작업 및 성과
- **열쇠 사용 시 점수 차감 기능 구현**
    - `GameRepository.usePrisonKey()`: 탈출 열쇠 사용 시 참가자 점수에서 **70점 차감** 로직 추가
    - **밸런스 근거**:
        - 체포 점수(100점)의 70%로 설정하여 열쇠의 강력한 역전 효과에 적절한 패널티 부여
        - 구출 점수(50점)보다 높게 설정하여 동료 없이 혼자 탈출하는 것의 비용 반영
        - 5분간 구출 불가 페널티와 함께 작용하여 전략적 선택지로 유지
- **점수 시스템 문서화**
    - `docs/plan.md`: 점수 시스템 섹션에 구체적인 수치 명시
        - 경찰 체포: 100점
        - 도둑 구출: 50점
        - 도둑 생존: 1초당 1점
        - 열쇠 사용: -70점

#### 📝 비고 / 특이사항
- **게임 밸런스 고려사항**:
    - 현재 점수 시스템에서 도둑의 생존 점수가 빠르게 누적되는 문제가 있어 열쇠 사용에 적절한 패널티 부여가 중요
    - 70점 차감은 2분 이상 잡혀 있었던 도둑에게는 합리적인 선택이 될 수 있음
    - 향후 플레이 테스트를 통해 적절성 검증 필요 (50~100점 범위에서 조정 가능)
- **향후 개선 방향**:
    - 전반적인 점수 밸런스 재조정 필요 (경찰 체포 점수를 플레이 시간에 비례하여 증가시키는 방안 검토)

#### 🔗 관련 문서
- 수정 파일:
    - `lib/features/game/data/game_repository.dart` - 열쇠 사용 시 점수 차감 로직 추가
    - `docs/plan.md` - 점수 시스템 구체화

---

### 🐛 버그 수정: 감옥 화면 게임 종료 처리 (Prison Screen Game End Handling)

#### ✅ 주요 작업 및 성과
- **문제 해결**
    - **문제 현상**: 도둑이 수감되어 감옥 화면(`PrisonScreen`)에 있을 때 게임이 종료되어도 결과 화면으로 이동하지 않음
    - **추가 문제**: 감옥 화면에서 게임 남은 시간이 표시되지 않아 게임 진행 상황 파악 불가
- **타이머 시스템 구현**
    - `PlayScreen`과 동일한 타이머 로직을 `PrisonScreen`에 적용
    - **서버 시간 동기화**: `_initServerTimeOffset()`으로 서버 시간과 로컬 시간의 offset 계산
    - **주기적 업데이트**: `Timer.periodic`을 사용하여 1초마다 화면 갱신
    - **시간 계산**: 서버 시간 기준으로 정확한 남은 시간 계산 및 표시
- **게임 종료 감지 및 자동 네비게이션**
    - 게임 상태(`game.status`)를 실시간으로 감시하여 `GameStatus.finished` 감지
    - 종료 감지 시 `context.go('/result/${gameId}')`로 결과 화면으로 자동 이동
    - `WidgetsBinding.instance.addPostFrameCallback`을 사용하여 빌드 사이클 중 안전한 네비게이션 보장
- **UI 개선**
    - 화면 상단에 타이머 섹션 추가 (`GlassContainer` 스타일)
    - 레드 네온 테마로 48pt 크기의 남은 시간 표시
    - MM:SS 형식의 `_formatDuration()` 메서드로 가독성 향상

#### 📝 비고 / 특이사항
- **코드 일관성**: `PlayScreen`과 완전히 동일한 타이머 및 서버 시간 동기화 로직 적용하여 일관성 유지
- **리소스 관리**: `dispose()` 메서드에서 타이머를 올바르게 정리하여 메모리 누수 방지
- **안전한 비동기 처리**: 모든 비동기 작업에서 `mounted` 체크를 통해 위젯 unmounted 상태 오류 방지
- **UI/UX**: 감옥 화면에서도 게임 진행 상황을 실시간으로 파악할 수 있어 사용자 경험 개선

#### 🔗 관련 문서
- 수정 파일:
    - `lib/features/game/presentation/prison_screen.dart` - 타이머 로직, 게임 종료 처리, UI 추가

---

### 🐛 버그 수정: 타이머 동기화 문제 해결 (Timer Synchronization Fix)

#### ✅ 주요 작업 및 성과
- **문제 원인 분석 및 해결**
    - **문제 현상**: 실제 기기 3대 테스트 중 방장과 참여자 간 타이머가 다르게 표시되는 현상 발견
        - 방장(갤럭시 S23): 5분부터 정상 카운트다운
        - 참여자 기기 1: 13분부터 시작
        - 참여자 기기 2: 5분 몇초부터 시작
    - **근본 원인**: `PlayScreen`에서 각 기기의 로컬 시스템 시간(`DateTime.now()`)을 사용하여 남은 시간 계산
        - 기기마다 시스템 시간 설정이 다르면 타이머가 다르게 표시됨
        - 방장이 게임 시작 시 자신의 로컬 시간 기준으로 `endsAt` 계산
- **Firestore 서버 타임스탬프 기반 Offset 계산 구현**
    - `GameRepository.calculateServerTimeOffset()`: 서버 시간과 로컬 시간의 차이(offset) 계산
        - Firestore `_timesync` 컬렉션에 더미 문서 작성하여 서버 타임스탬프 획득
        - 네트워크 왕복 시간(RTT)의 절반을 보정하여 정확도 향상
        - offset = 서버 시간 - 로컬 시간
    - `GameRepository.getEstimatedServerTime()`: offset을 적용한 추정 서버 시간 반환
    - `PlayScreen`: 화면 진입 시 offset 초기화 및 서버 시간 기준으로 남은 시간 계산
        - `_remainingTime = game.endsAt!.difference(estimatedServerTime)`
- **견고한 예외 처리 구현**
    - **타임아웃 처리**: Firestore 작업에 5초 타임아웃 설정으로 네트워크 지연 환경 대응
    - **리소스 정리**: `finally` 블록으로 더미 문서 삭제 보장 (삭제 실패 시에도 무시)
    - **Fallback 전략**: 모든 예외 발생 시 `Duration.zero` 반환하여 로컬 시간 사용
    - **타입 안전성**: `doc.data()`를 `Map<String, dynamic>?`로 명시적 캐스팅하여 null-safety 준수

#### 📝 비고 / 특이사항
- **기술적 결정**: 
    - 서버 시간 offset은 `PlayScreen` 진입 시마다 계산 (Firestore 읽기/쓰기 1회 추가, 약 100-300ms)
    - 향후 앱 최초 실행 시 한 번만 계산하고 전역으로 관리하는 방식으로 개선 가능
    - 주기적 offset 갱신(예: 5분마다)도 고려 가능
- **정확도**: 네트워크 왕복 시간 보정으로 일반적인 환경에서 ±100ms 이내의 정확도 예상
- **안정성**: offset 계산 실패 시에도 앱이 정상 작동하도록 graceful fallback 구현
- **검증**: `flutter analyze` 통과 (No issues found!)

#### 🔗 관련 문서
- 수정 파일:
    - `lib/features/game/data/game_repository.dart` - offset 계산 메서드 추가
    - `lib/features/game/presentation/play_screen.dart` - 서버 시간 기반 타이머 계산

---

## 2026-01-10 (토)

### 🧹 코드 품질 개선: 공통 위젯 리팩토링 (Common Widget Refactoring)

#### ✅ 주요 작업 및 성과
- **공통 위젯 추출 및 통합**
    - 8개 화면에서 중복되는 UI 컴포넌트를 `lib/core/widgets`로 추출하여 코드 재사용성 극대화
    - **추출된 위젯**: `HudText`, `GlassContainer`, `SciFiButton`, `GradientBorder`, `HudSectionHeader`, `ParticipantCounter`
    - 각 화면에서 로컬로 정의되었던 동일 위젯(예: `_HudText`, `_GlassContainer`)을 공통 위젯으로 전면 교체
- **Screen 파일 내 로컬 위젯 분리**
    - screen 파일에 포함되어 있던 로컬 위젯 클래스 6개를 별도 파일로 분리하여 코드 구조 명확화
    - **onboarding 위젯** (`lib/features/onboarding/widgets/`):
        - `FloatingWidget`: 플로팅 애니메이션 래퍼
        - `GlassAvatar`: 글래스모피즘 스타일 아바타
        - `NeonIconButton`: 네온 스타일 아이콘 버튼
        - `OnboardingTextField`: 온보딩 전용 텍스트 필드
    - **game 위젯** (`lib/features/game/presentation/widgets/`):
        - `QrScanOverlay`: QR 스캔 화면 오버레이
    - `onboarding_screen.dart`: 397 → 176 라인 (55% 감소, 221 라인 제거)
    - `join_game_screen.dart`: 436 → 361 라인 (17% 감소, 75 라인 제거)
- **Lint 이슈 완전 해결**
    - 9개의 마이너 lint 이슈(미사용 import, deprecated API 사용 등)를 모두 수정
    - `withOpacity()` deprecated → `withValues(alpha: ...)` 최신 API로 전환
    - `ParticipantCounter` 위젯 생성하여 누락된 컴포넌트 해결
    - **최종 결과**: `flutter analyze` 실행 시 **No issues found!** 달성

#### 📝 비고 / 특이사항
- **디렉토리 구조 정립**:
    - `lib/core/widgets/`: 앱 전체에서 사용하는 범용 공통 위젯
    - `lib/features/[feature]/widgets/`: 특정 feature에만 사용되는 전용 위젯
    - 이러한 구조는 관심사의 분리와 추후 모듈화에 유리
- **코드 품질 향상**:
    - 총 300+ 라인의 중복 위젯 정의 제거
    - 모든 화면에서 일관된 디자인 시스템 적용 가능
    - 위젯 수정 시 한 곳만 변경하면 전체 앱에 반영되어 유지보수성 대폭 향상

### 🚀 게임 실행 화면 UI 리디자인 (Game Play Screens UI Redesign)

#### ✅ 주요 작업 및 성과
- **게임 플레이 화면(`PlayScreen`), 수감 화면(`PrisonScreen`), QR 스캔 화면(`QrScanScreen`), 결과 화면(`ResultScreen`) 리디자인**
    - **일관된 HUD 테마**: 홈 및 로비 화면에서 구축된 Futuristic, Neon, Glassmorphism 스타일을 플레이 관련 모든 화면으로 확산
    - **결과 화면(`ResultScreen`)**:
        - 승리 진영에 따라 블루/레드 네온 액센트가 적용된 대형 트로피 배너와 HUD 스타일 순위표 구현
        - 특별 칭호(MVP, 검거왕 등)를 유리 질감 패널에 담아 시각적 주목도 향상
    - **플레이 화면(`PlayScreen`)**: 
        - 상단 중앙에 강렬한 네온 HUD 타이머를 배치하여 실시간 긴박감 극대화
        - 하단에 글래스모피즘 상태 보드와 블루-레드 그라데이션이 적용된 SciFi 액션 버튼 구현
    - **수감 화면(`PrisonScreen`)**:
        - 수감 중임을 시각적으로 명확히 전달하도록 레드 네온 테마와 "DETENTION ACTIVE" HUD 스타일 적용
        - NFC 관련 모든 안내 및 스캔 창을 글래스모피즘 기반 커스텀 다이얼로그로 통합
    - **QR 스캔 화면(`QrScanScreen`)**:
        - 카메라 화면 위에 정밀한 네온 가이드 프레임과 코너 액센트를 오버레이하여 미래 장비 조작 느낌 구현
        - 하단 안내 패널에 블러 효과가 적용된 글래스 컨테이너를 배치하여 시인성 및 현대적 미학 확보

### 🚀 로비 화면 UI 리디자인 (Lobby Screen UI Redesign)

#### ✅ 주요 작업 및 성과
- **로비 화면(`LobbyScreen`) 리디자인 및 HUD 고도화**
    - **전투 대기실 HUD**: "전투 대기실" 컨셉으로 시스템 배경 이미지를 최적화하고 투명 앱바를 적용하여 공간감 확장
    - **요원 목록 및 인원 관리**: 
        - 보직별(경찰/도둑) 네온 컬러 테마 적용 및 사령부용 'YOU' 태그 등 디테출 추가
        - 요원 아이콘에 글로우 효과가 적용된 서클 아바타 인터페이스 구현
    - **커스텀 다이얼로그 시스템**: 나가기 확인, NFC 등록 안내, 인원 설정 오류 등 모든 팝업 UI를 글래스모피즘 기반의 HUD 스타일로 전면 개편
    - **인터랙티브 UI**: 하단 요원 보직 변경 시트(BottomSheet)에 블러 효과 및 네온 스타일 적용

### 🚀 게임 생성 및 참가 화면 UI 리디자인 (Create & Join Game Screens UI Redesign)

#### ✅ 주요 작업 및 성과
- **게임 만들기(`CreateGameScreen`) 및 게임 참가하기(`JoinGameScreen`) 리디자인**
    - **통합 브랜드 스타일 적용**: 홈 화면에 이어 "CatchRun"의 시그니처 HUD 스타일을 게임 진입 프로세스 전반에 확산
    - **게임 만들기 화면 개선**:
        - **입력 폼 현대화**: 글래스모피즘 테이너와 네온 그라데이션 테두리가 적용된 `_HudTextField` 적용
        - **인원 설정 경험 개선**: 경찰(블루)/도둑(레드) 테마가 적용된 직관적인 카운터 버튼 및 슬라이더 UI 구현
    - **게임 참가하기 화면 개선**:
        - **TabBar 커스텀 스타일링**: 네온 컬러와 글로우 효과가 적용된 탐색 탭 구현
        - **QR 스캔 HUD 오버레이**: 카메라 화면 위에 네온 가이드 프레임과 HUD 텍스트를 중첩시켜 게임적 몰입감 극대화
    - **커스텀 다이얼로그**: 카메라 권한 요청 등 시스템 메시지를 글래스모피즘 기반의 HUD 디자인으로 통일하여 비주얼 일관성 확보

#### 📝 비고 / 특이사항
- **위젯 재사용**: `_HudText`, `_SciFiButton`, `_GlassContainer` 등 홈 화면에서 검증된 위젯 로직을 동일하게 적용하여 개발 효율성 및 디자인 정합성 유지

### 🚀 홈 화면 UI 리디자인 (Home Screen UI Redesign)

#### ✅ 주요 작업 및 성과
- **홈 화면(Home Screen) 디자인 전면 리스킨**
    - **디자인 통일성**: 프로필 설정 화면의 Futuristic, Neon, Glassmorphism 컨셉을 홈 화면에 동일하게 이식
    - **핵심 스타일 적용**:
        - 배경: `OrientationBuilder`를 통한 가로/세로 배경 이미지 최적화 및 블랙 그라데이션 오버레이 추가
        - 글래스모피즘: 프로필 섹션 및 대화 상자에 `BackdropFilter` 기반 유리 질감 패널 적용
        - 네온 버튼: 경찰(블루)-도둑(레드) 그라데이션과 광원 효과가 포함된 `_SciFiButton` 구현
        - HUD 텍스트: 글로우 효과와 높은 자간이 적용된 게임 HUD 스타일 타이포그래피 적용
    - **기능 유지**: 레이아웃과 데이터 흐름을 그대로 유지하면서 시각적 요소만 "CatchRun" 브랜드 아이덴티티에 맞춰 강화
    - **UX 최적화**: 로그아웃 다이얼로그를 시스템 기본형에서 글래스모피즘 HUD 스타일로 커스텀 디자인하여 몰입감 유지


### 🚀 프로필 설정 화면 UI 고도화 (Onboarding Screen UI Polish)

#### ✅ 주요 작업 및 성과
- **프로필 설정 화면(Onboarding Screen) HUD 스타일 전면 개편**
    - **디자인 테마**: Futuristic, Neon, Glassmorphism, Cyber Sport 컨셉을 적용하여 게임 로비와 같은 몰입감 있는 UI 구축
    - **핵심 기술**: `BackdropFilter`를 사용한 Glassmorphism 패널, `LinearGradient` 및 `BoxShadow`를 활용한 Neon Glow 효과, `AnimatedContainer` 기반의 Floating 애니메이션 적용
    - **컴포넌트 고도화**:
        - 아바타: 원형 Glass 패널과 외곽의 네온 링, 플로팅 효과가 적용된 아바타 영역 구현
        - 텍스트 필드: 그라데이션 네온 테두리와 반투명 배경이 적용된 HUD 스타일 입력 필드 적용
        - 시작하기 버튼: 블루-레드 그라데이션과 강력한 외곽 광원 효과가 적용된 '미션 시작' 버튼 구현
    - **사용자 경험(UX) 최적화**: 모든 영문 HUD 텍스트의 한국어화 및 게임 HUD 타이포그래피 스타일(자간 조정 등) 적용
    - **레이아웃 수정**: 배경 이미지 하단 공백 방지를 위한 레이아웃 제약 추가 및 가독성 향상을 위한 배경 오버레이 농도 조정

### 🚀 로그인 화면 디자인 고도화 (Login Screen UI Polish)

#### ✅ 주요 작업 및 성과
- **구글 로그인 버튼 이미지 교체**
    - 기존 `ElevatedButton` 형태의 구글 로그인 버튼을 고해상도 브랜드 이미지(`android_neutral_sq_ctn@4x.png`)로 교체
    - `InkWell`을 적용하여 이미지 클릭 시에도 시각적 피드백과 함께 로그인 로직이 정상 작동하도록 구현
    - 버튼 높이를 56px로 고정하여 기존 레이아웃과의 일관성 유지

### 🚀 보안 강화 및 환경 변수 관리 도입 (Security & Config Enhancement)

#### ✅ 주요 작업 및 성과
- **환경 변수 관리 체계 전환 (`flutter_config` → `flutter_dotenv`)**
    - 최신 Flutter/Android 환경(AGP 8.0+)과 호환되지 않는 `flutter_config`를 제거하고 안정적인 `flutter_dotenv`로 대체
    - `.env` 파일의 에셋 등록 및 `main.dart`, `firebase_options.dart` 코드 업데이트
- **Android 빌드 환경 최신화 및 이슈 해결**
    - 모든 서브프로젝트의 `jvmTarget`을 17로, `compileSdk`를 36으로 강제 동기화하여 플러그인 간 충돌 방지
    - AGP 8.0의 엄격한 `namespace` 및 Manifest `package` 속성 이슈를 Gradle 스크립트 최적화를 통해 해결
- **런타임 안정성 및 보안 강화**
    - AndroidManifest.xml에서 `FirebaseInitProvider`를 제거하여 네이티브 자동 초기화 간섭 차단
    - `FirebaseOptions`를 `static getter`로 변경하여 `.env` 로드 후 올바른 API Key를 사용하도록 보장
    - Firebase 중복 초기화 방지 로직 적용 및 예외 처리 강화
    - `.env` 파일을 통한 API Key 등 민감 정보의 안전한 관리 체계 구축
- **Firebase API Key 보호 및 연동**
    - `firebase_options.dart`: 하드코딩된 API Key를 `FlutterConfig.get()` 호출로 대체하여 보안성 확보
    - `main.dart`: 앱 시작 시 `FlutterConfig.loadEnvVariables()` 호출 및 `AppConfig` 초기화 로직을 `.env` 기반으로 전환
- **Git 히스토리 정화 (Security Scrubbing)**
    - `git filter-repo`를 사용하여 이전 커밋 히스토리에 노출된 모든 API Key 문자열을 영구적으로 제거 및 치환
- **보안 가이드 수립**
    - `.env.example` 템플릿 제공을 통해 협업 환경에서 필요한 환경 변수 구성 안내

#### 📝 비고 / 특이사항
- **주의 사항**: 히스토리 정화 후 원격 저장소에 `force push`가 이루어졌으며, 팀원들은 로컬 저장소를 재설정하거나 최신 히스토리로 덮어써야 함.
- **향후 계획**: 새로운 민감 정보(예: 결제 키, 외부 API API Key) 추가 시 항상 `.env`를 최우선으로 사용할 것.

---

## 2026-01-09 (금)

### 🚀 로그인 및 스플래시 화면 UI 고도화 (Auth & Splash UI Polish)

#### ✅ 주요 작업 및 성과
- **화면 회전 대응 배경 이미지 구현**
    - `OrientationBuilder`를 활용하여 가로/세로 모드에 최적화된 배경 이미지(`login_screen_portrait.png`, `login_screen_landscape.png`) 자동 전환 로직 구현
    - `BoxFit.cover` 적용으로 모든 해상도에서 공백 없는 풀스크린 배경 실현
- **공통 배경 위젯 (`AuthBackground`) 추출**
    - 로그인 화면과 스플래시 화면에서 동일한 배경 및 오버레이(`opacity: 0.4`) 로직을 공유하도록 리팩토링하여 코드 중복 제거 및 유지보수성 향상
- **타이틀 UI 개선**
    - 기존 'CATCH RUN' 텍스트 및 부제목을 `title_logo.png` 이미지로 대체하여 브랜드 아이덴티티 강화
    - **로고 테두리 보정**: `ShaderMask`와 `RadialGradient`를 사용하여 누끼 처리가 거친 로고의 외곽선을 부드럽게 페이드 처리. 배경과 자연스럽게 어우러지도록 최적화
- **스플래시 화면 최적화**
    - 로그인 화면과 동일한 배경을 적용하여 앱 진입 시부터 일관된 사용자 경험 제공
    - 어두운 배경에서 시인성 확보를 위해 `CircularProgressIndicator` 색상을 화이트로 조정

#### 📝 비고 / 특이사항
- **기술적 결정**: 로고가 가로로 긴 형태임을 고려하여 `RadialGradient`의 `radius`를 1.5로 설정하고 `stops` 값을 조정하여 글자 가림 현상을 방지함.
- **UI 단순화**: 스플래시 화면의 Hero 로고를 제거하고 로딩 인디케이터만 남겨 간결하게 수정함.

---

## 2026-01-07 (수)

### 🚀 게스트 로그인 기능 추가 (Guest Login Support)

#### ✅ 주요 작업 및 성과
- **Firebase 익명 인증(Anonymous Auth) 통합**
    - `AuthRepository`: `signInAnonymously()` 메서드를 추가하여 구글 계정 없이도 인증 세션을 생성할 수 있도록 구현
    - `AuthController`: 익명 로그인 후 Firestore `users` 컬렉션에 사용자 문서를 자동 생성하는 로직(`_handleUserSignIn`) 추가
- **로그인 UI 개선**
    - `LoginScreen`: Google 로그인 버튼 하단에 "게스트로 시작하기" 버튼을 추가하여 접근성 향상
    - 디자인 일관성을 위해 `TextButton` 형태의 가벼운 UI 적용

#### 📝 비고 / 특이사항
- 익명 계정은 기기 데이터를 삭제하거나 로그아웃 시 정보를 잃을 수 있음을 사용자가 인지할 수 있도록 추후 안내 문구 보강 검토 필요.

---


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
