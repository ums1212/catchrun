### 공통 설계 원칙

- Material 3 + SafeArea 기본
- 화면별 구조: `Scaffold -> (AppBar?) -> Body`
- 상태/데이터:
  - `StreamBuilder`(Firestore) + `Riverpod/Bloc`(선호하는 상태관리) 조합 권장
  - 플레이 화면은 `Stack`으로 팝업/오버레이 처리
- 스캔(카메라) 화면은 라우트로 분리: `QrScanPage`, `NfcScanSheet` 등

### 라우팅 구조(권장)
GoRouter(또는 Navigator 2.0)
라우트 예:
/splash
/login
/onboarding
/home
/game/create
/game/join
/game/lobby/:gameId
/game/play/:gameId
/game/jail/:gameId (수감 전용, 플레이 라우트에서 조건부로 push 가능)
/game/result/:gameId
/qr/fullscreen (내 QR 전체화면 공용)

### S-01 스플래시 (SplashPage)
```
SplashPage
└─ Scaffold
   └─ SafeArea
      └─ Center
         └─ Column(mainAxisSize: min)
            ├─ AppLogo()
            ├─ SizedBox(h)
            └─ CircularProgressIndicator()
```

### S-02 로그인 (LoginPage)
```
LoginPage
└─ Scaffold
   └─ SafeArea
      └─ Padding(all: 24)
         └─ Column
            ├─ Spacer()
            ├─ AppLogo()
            ├─ SizedBox(h)
            ├─ Text("Google로 빠르게 시작해요")
            ├─ SizedBox(h)
            ├─ GoogleSignInButton()
            ├─ SizedBox(h)
            └─ Text("로그인 시 이용약관/개인정보 ...", style: caption)
```

### S-03 닉네임/아바타 설정 (OnboardingProfilePage)
```
OnboardingProfilePage
└─ Scaffold
   └─ SafeArea
      └─ Padding(all: 24)
         └─ Column
            ├─ Text("프로필 설정", style: title)
            ├─ SizedBox(h)
            ├─ AvatarPreview(seed)
            ├─ SizedBox(h)
            ├─ Row
            │  ├─ Expanded(NicknameTextField(initial: random))
            │  └─ IconButton(edit/refresh random)
            ├─ SizedBox(h)
            ├─ PrimaryButton("시작하기")
            └─ SizedBox(h)
```

### S-04 홈 (HomePage)
```
HomePage
└─ Scaffold
   └─ SafeArea
      └─ Padding(all: 20)
         └─ Column
            ├─ ProfileHeader(avatar, nickname)
            ├─ SizedBox(h)
            ├─ Expanded
            │  └─ Column(mainAxisAlignment: center)
            │     ├─ PrimaryCardButton("게임 만들기", icon: add)
            │     ├─ SizedBox(h)
            │     └─ PrimaryCardButton("게임 참가", icon: group)
            └─ Text("야외에서 안전하게 플레이하세요", style: caption)
```

### S-05 게임 만들기 (GameCreatePage)
```
GameCreatePage
└─ Scaffold
   ├─ AppBar(title: "게임 만들기")
   └─ SafeArea
      └─ ListView(padding: 20)
         ├─ TextField("게임 이름")
         ├─ SizedBox(h)
         ├─ DurationSelectorChips([5,10,15])
         ├─ SizedBox(h)
         ├─ RoleRatioSelector(
         │    copsCountStepper,
         │    robbersCountStepper
         │  )
         ├─ SizedBox(h)
         ├─ ToggleTile("QR 사용", value)
         ├─ ToggleTile("NFC 사용", value)
         ├─ SizedBox(h)
         └─ PrimaryButton("게임 생성")
```

### S-06 게임 참가 (GameJoinPage) — 코드 입력 + QR 입장
```
GameJoinPage
└─ Scaffold
   ├─ AppBar(title: "게임 참가")
   └─ SafeArea
      └─ Padding(all: 20)
         └─ Column
            ├─ SegmentedControl(["코드 입력", "QR로 입장"])
            ├─ SizedBox(h)

            ├─ Expanded(
            │   IndexedStack(index)
            │   ├─ [코드 입력]
            │   │  └─ Column
            │   │     ├─ TextField("게임 번호(9자리)")
            │   │     ├─ TextField("초대 코드(6자리)")
            │   │     ├─ SizedBox(h)
            │   │     └─ PrimaryButton("참가")
            │   └─ [QR로 입장]
            │      └─ QrScannerPreview(
            │            onDetected: joinQrToken
            │         )
            └─ SafetyHintFooter()
```

### S-07 대기방 (LobbyPage) — 역할 배정 개선 포함
```
LobbyPage(gameId)
└─ Scaffold
   ├─ AppBar(title: "대기방")
   └─ SafeArea
      └─ StreamBuilder(GameDoc + Participants)
         └─ Column
            ├─ GameInfoCard(
            │    gameCode, inviteCode,
            │    duration, ruleSummary
            │  )
            ├─ SizedBox(h)

            ├─ JoinQrCard( // 방장 화면에 크게 표시
            │    QrImage(data: joinQrToken),
            │    Text("QR로 스캔하면 바로 입장")
            │  )

            ├─ SizedBox(h)

            ├─ Expanded
            │  └─ ParticipantsListView(
            │      items: participants,
            │      onLongPressItem: (isHost) => RoleChangeBottomSheet
            │    )

            ├─ if (role == robber) PoliceVolunteerToggle(
            │      label: "경찰 지원",
            │      value: wantsCop
            │    )

            ├─ SizedBox(h)

            └─ if (isHost)
               PrimaryButton("게임 시작")
```
RoleChangeBottomSheet (방장용)
길게 누른 참가자 → 역할: 경찰/도둑 토글, roleLock 토글

### S-08 게임 플레이 (GamePlayPage) — 오버레이/QR/팝업 포함
```
GamePlayPage(gameId)
└─ Scaffold
   └─ SafeArea
      └─ StreamBuilder(GameDoc + MyParticipant + Events)
         └─ Stack
            ├─ Column
            │  ├─ TopStatusBar(
            │  │    timeRemaining,
            │  │    roleChip,
            │  │    ifCop: "남은 도둑 X / 전체 Y"
            │  │  )
            │  ├─ SizedBox(h)
            │  ├─ Expanded
            │  │  └─ Center
            │  │     └─ StatusCard(
            │  │        stateBadge: free/jailed,
            │  │        hintText: 역할별 안내
            │  │     )
            │  ├─ SizedBox(h)
            │  └─ BottomActionBar
            │     ├─ ifCop: PrimaryButton("QR 스캔") + SecondaryButton("NFC 태그")
            │     └─ ifRobber: PrimaryButton("내 QR 코드 보기")
            │
            ├─ EventPopupOverlay(visibleWhen: latestEventForMe)
            │   // "열쇠 사용됨! 도둑 탈출!" 같은 전체화면 팝업
            │
            ├─ if (showFullscreenMyQr)
            │    FullscreenQrOverlay(
            │       data: myQrPayload,
            │       onClose: X
            │    )
            │
            └─ if (isRobber && state == jailed)
                 // 수감 상태가 되면 자동으로 감옥 화면으로 라우팅하거나,
                 // 여기서 JailOverlay로 강제 전환 가능
                 JailAutoRouteGuard()
```
핵심 UX
도둑: 내 QR 버튼 → 전체 화면 QR 오버레이
경찰: 상단에 남은 도둑/전체 도둑 실시간 표시
열쇠 사용 이벤트: EventPopupOverlay에서 전체 화면 팝업 + 진동/사운드 트리거

### S-09 감옥 (JailPage) — 진입 시 자동 QR 크게 표시
```
JailPage(gameId)
└─ Scaffold
   └─ SafeArea
      └─ StreamBuilder(MyParticipant + GameDoc)
         └─ Column
            ├─ Text("감옥", style: title)
            ├─ SizedBox(h)
            ├─ Text("이동할 수 없습니다. 여기서 대기하세요.", style: body)
            ├─ SizedBox(h)
            ├─ Expanded
            │  └─ Center
            │     └─ QrCardLarge(
            │          QrImage(data: myQrPayload, size: large),
            │          Text("구출자가 이 QR을 스캔하면 탈출!")
            │        )
            ├─ SizedBox(h)
            └─ SecondaryButton("내 상태 새로고침") // 선택
```

### S-10 결과 (ResultPage) — 순위 + 칭호
```
ResultPage(gameId)
└─ Scaffold
   ├─ AppBar(title: "결과")
   └─ SafeArea
      └─ StreamBuilder(GameDoc + Participants)
         └─ ListView(padding: 20)
            ├─ WinnerBanner(team: cops/robbers)
            ├─ SizedBox(h)
            ├─ TitleChipsRow([
            │    "가장 많이 잡은 경찰: 닉네임",
            │    "가장 많이 구출한 도둑: 닉네임",
            │    "최장 생존 도둑: 닉네임",
            │    "MVP: 닉네임"
            │  ])
            ├─ SizedBox(h)
            ├─ LeaderboardList(
            │    items: participantsSortedByScore
            │  )
            └─ PrimaryButton("홈으로")
```

### 공용 컴포넌트(재사용 추천)
ProfileHeader
PrimaryCardButton
GameInfoCard
JoinQrCard
ParticipantsListView + RoleChangeBottomSheet
TopStatusBar
StatusCard
BottomActionBar
FullscreenQrOverlay
EventPopupOverlay
LeaderboardList

### 오버레이/팝업 처리(실전 팁)
- EventPopupOverlay는 Stack 최상단에서
  - AnimatedOpacity + ScaleTransition로 짧게 보여주기
- 팝업 표시 트리거:
  - events 컬렉션 최신 이벤트를 구독하고,
  - audience가 내 역할과 맞으면 표시
- 사운드/진동은 팝업 표시 시점에 1회만 실행(중복 방지)