# 개발 로그 (Development Log)

## 2026-01-04 (일)
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
