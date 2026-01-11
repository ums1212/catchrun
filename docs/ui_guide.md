# 🎨 UI/UX 디자인 가이드: 시스템 네비게이션 바 대응

Android의 에지 투 에지(Edge-to-Edge) 모드 및 하단 네비게이션 바 버튼 환경에서 콘텐츠가 가려지지 않도록 하기 위한 가이드입니다.

## 1. 기본 원칙
- **콘텐츠 가림 방지**: 하단 네비게이션 바 버튼이 화면의 주요 콘텐츠(버튼, 입력란 등)를 가리지 않아야 합니다.
- **에지 투 에지 모드**: 안드로이드 15 대응을 위해 상태 바와 네비게이션 바는 원칙적으로 **투명(Transparent)**하게 유지합니다.

## 2. 디자인 철학: 왜 화면별(Body) SafeArea인가?
전역(Global) `SafeArea`를 사용하지 않고 각 화면의 `body`에서 개별적으로 처리하는 이유는 다음과 같습니다.

- **시스템 바 블리딩(Bleeding) 효과**: `AppBar`가 상태 바(Status Bar) 영역까지, 하단 바가 네비게이션 바 영역까지 색상이 자연스럽게 이어지게 하여 더 넓고 프리미엄한 화면 몰입감을 제공합니다.
- **세밀한 제어(Granular Control)**: 배경 이미지는 전체 화면에 꽉 채우되(SafeArea 밖), 텍스트나 버튼만 안전 영역 안으로 배치해야 하는 등 화면마다 다른 디자인 요구사항에 유연하게 대응할 수 있습니다.
- **Scaffold와의 조화**: 플러터의 `Scaffold`는 `appBar`와 `bottomNavigationBar`가 시스템 안전 영역을 자동으로 계산하도록 설계되어 있습니다. 따라서 개발자는 오직 `body`의 내용만 안전하게 보호하면 됩니다.

## 3. 기술적 구현 (Flutter)
### SafeArea 사용 (필수)
모든 화면의 `Scaffold` 바디는 원칙적으로 `SafeArea`로 감싸야 합니다. 특히 하단(bottom) 패딩 확보가 중요합니다.

```dart
Scaffold(
  appBar: AppBar(...),
  body: SafeArea(
    bottom: true, // 네비게이션 바 영역 확보
    child: Column(
      children: [
        Expanded(child: Content()),
        BottomButton(), // SafeArea 덕분에 가려지지 않음
      ],
    ),
  ),
)
```

### 시스템 바 투명화 (`main.dart`)
`SystemChrome`을 통해 앱 시작 시 시스템 바를 투명하게 설정합니다.

```dart
SystemChrome.setSystemUIOverlayStyle(
  const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ),
);
SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
```

## 3. 향후 개발 시 주의사항
- **새 화면 추가 시**: 반드시 `Scaffold`의 `body`를 `SafeArea`로 감싸는 것을 기본값으로 생각하세요.
- **바텀 시트(Bottom Sheet)**: 하단 시트 구현 시에도 내부 콘텐츠가 네비게이션 바와 겹치지 않도록 내부 패딩이나 `SafeArea`를 고려해야 합니다.
- **테스트**: 하단 네비게이션 바를 '제스처' 모드가 아닌 '버튼' 모드로 설정한 안드로이드 기기/에뮬레이터에서 반드시 하단 버튼 클릭 여부를 확인하세요.
