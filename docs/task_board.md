# ✅ 캐치런 MVP 개발 태스크 보드

## Backlog (추후)
- 경찰 스캐너 아이템(근처 도둑 위치 힌트, 일회성/점수차감/쿨타임)
- 전적/랭킹/시즌
- 감옥 위치(GPS/지오펜싱) 강제(현재 MVP는 UI/룰 기반)
- 치팅 방지 강화(Cloud Functions authoritative server)
- 장기 미사용(미완성 프로필) 유령 회원 자동 삭제 시스템 (@user_cleanup_design.md)
- **NFC 고도화**: NFC 태그 시 앱 자동 실행(AAR) 및 미설치 시 마켓(Deep Link) 이동 기능
- 경찰과 도둑 활동내역(탈출, 수감, 열쇠 사용 등)을 플레이화면에서 로그 목록으로 표시할 수 있는 버튼 추가(파이어스토어에 로그 저장)
- 화면전환 애니메이션 확인 (흰색 깜빡임)
- 스플래시스크린의 배경색 지정방법 확인

## Sprint 0 — 프로젝트 세팅 (Foundation)
### 목표(DoD)
- 앱 실행 → 스플래시/로그인/홈까지 라우팅 정상
- Firebase 연결 및 빌드 성공(iOS/Android)
### Tasks
- Flutter 프로젝트 생성 + 패키지명/번들ID 확정
- Firebase 프로젝트 생성, iOS/Android 연동(google-services / plist)
- 기본 라우팅(GoRouter) 구성: /splash, /login, /onboarding, /home
- 공통 테마(Material3) + 공통 버튼/카드 컴포넌트 스켈레톤
- 환경 분리(Dev/Prod) 최소 구성(선택)

## Sprint 1 — 인증/프로필 (Auth & User)
### 목표(DoD)
- Google 로그인 완료
- 최초 로그인 시 닉네임 랜덤 생성(수정 가능) + avatarSeed 저장
- 이후 앱 재실행 시 자동 로그인/홈 진입
### Tasks
- Firebase Auth Google 로그인 구현
- users/{uid} 생성/업데이트(닉네임, avatarSeed, timestamps)
- 랜덤 닉네임 생성 로직 + “다시 뽑기/편집” UI(S-03)
- 홈(S-04) 프로필 헤더(닉네임/아바타 표시)
- [x] 아바타 랜덤 생성 및 프리셋 이미지(profile1~4) 연동
- 로그아웃(디버그 메뉴로 숨겨도 OK)

## Sprint 2 — Firestore 스키마/규칙 + 게임 생성/참가(로비 입장)
### 목표(DoD)
- 게임 생성 → 9자리 게임번호 + 6자리 초대코드 자동생성
- 코드 입력 또는 QR 입장으로 대기방 합류 가능
- 대기방에서 참가자 리스트 실시간 업데이트
### Tasks (DB/규칙)
- Firestore 컬렉션/문서 구조 확정 및 구현:
- games, participants, events, gameCodes
- 최소 Security Rules(로그인 필수, 게임/참가자 read/write 범위 제한)
- gameCodes/{9자리} 매핑 생성/조회 로직
### Tasks (화면)
- 게임 만들기(S-05) UI + 생성 API
- 게임 참가(S-06) “코드 입력 탭” UI + 검증(초대코드)
- QR 입장 기능:
  - joinQrToken 생성/저장
  - 대기방에서 입장용 QR 표시
  - 참가 화면에서 QR 스캔 → gameId resolve → 참가
- 대기방(S-07) 실시간 참가자 리스트/게임 정보 표시

## Sprint 3 — 역할 배정(자동+수동) + 게임 시작/타이머/종료
### 목표(DoD)
- 역할 자동 배정이 기본
- “경찰 지원” 및 방장 Long-press로 역할 변경/고정 가능
- 방장이 게임 시작 → 타이머 표시 → 종료 조건 적용
- 방장 직접 지정 방식 역할 변경 (RoleChangeBottomSheet)
- [x] 방장 본인 클릭 시 즉시 역할 변경 UX 개선 (중간 메뉴 제거)
- [x] 대기방(S-07) 방장의 참여자 강퇴(Kick) 기능 추가 및 강퇴 알림 구현
### Tasks (게임 시작/타이머/종료)
- 방장 “게임 시작”:
  - status=playing, startedAt, endsAt 세팅
  - events에 GAME_STARTED 기록
- 플레이 화면(S-08) 기본 골격 + 남은 시간 표시
- 종료 조건:
  - 모든 도둑 수감 시 즉시 종료(경찰 승)
  - endsAt 도달 시 자유 도둑 존재하면 도둑 승
  - status=finished + GAME_ENDED 이벤트

## Sprint 4 — QR 판정: 체포/구출 + 감옥 화면(자동 QR)
### 목표(DoD)
- 경찰이 QR 스캔으로 도둑 체포 가능
- 도둑이 감옥에서 수감 도둑 QR 스캔으로 구출 가능
- 수감 시 감옥 화면(S-09) 자동 진입 + 내 QR 크게 표시
- 경찰 화면에 “남은 도둑/전체 도둑” 실시간 표시
### Tasks (QR/내 QR)
- “내 QR 코드 보기”(S-08 도둑용) 전체화면 오버레이
- QR 페이로드 포맷 확정: 예) catchrun:{gameId}:{uid}:{nonce}
- QR 스캔 라우트/모듈 분리(QrScanPage)
### Tasks (트랜잭션)
- catchRobber(gameId, copUid, robberUid) 트랜잭션
  - robber: free -> jailed, jailedAt
  - cop stats.catches + score
  - games.counts 업데이트
  - events: CAUGHT
- rescueRobber(gameId, rescuerUid, jailedUid) 트랜잭션
  - jailed: jailed -> free, releasedAt
  - rescuer stats.rescues + score
  - games.counts 업데이트
  - events: RESCUED
### Tasks (감옥 화면)
- 수감 상태 감지 시 S-09로 자동 라우팅(또는 강제 overlay)
- S-09 진입 시 내 QR 자동 전체 표시
- 감옥 안내 문구(이동 불가 룰 명시)

## Sprint 5 — NFC 감옥 열쇠 + 경찰 전체 팝업(이벤트)
### 목표(DoD)
- 도둑(수감)이 NFC 열쇠 사용 → 즉시 자유 전환
- 사용 도둑은 5분간 구출 불가
- 모든 경찰에게 “열쇠 사용됨! 도둑 탈출!” 전체 팝업 + 사운드/진동 1회
### Tasks
- NFC 태그 읽기 플로우 구현(권한/가이드 포함)
- usePrisonKey(gameId, uid, nfcKeyId) 트랜잭션
  - 1회성 검증(games.keyItem.usedByUid == null)
  - user: jailed -> free
  - rescueDisabledUntil = now + 300s
  - games.keyItem.usedByUid/usedAt 세팅
  - games.counts 업데이트
  - events: KEY_USED (audience=cops)
- 플레이 화면에서 events 구독 → EventPopupOverlay 구현
- 팝업 중복 방지(최근 eventId 캐시)

## Sprint 6 — 점수/결과/칭호 + 폴리싱
### 목표(DoD)
- 게임 종료 시 결과 화면(S-10)에서 순위/칭호 표시
- “가장 많이 잡은 경찰/가장 많이 구출한 도둑/최장 생존/MVP” 산출
- 기본 예외 케이스(중도 이탈, 중복 스캔) 처리
### Tasks (점수)
- 점수 규칙 확정값을 games.score로 관리(서버/호스트 기준)
- 생존 점수 산정 방식 선택(권장: 종료 시 일괄 계산)
  - 도둑 생존시간 = finishedAt - startedAt - jailedDuration(선택)
- 아이템 점수 차감(현재는 열쇠는 차감 없음/있음 정책 결정)
### Tasks (결과 UI)
- ResultPage: 승리팀 배너 + 리더보드
- 칭호 계산 로직:
  - most catches (cop)
  - most rescues (robber)
  - longest survival (robber)
  - MVP (score max)
### Tasks (안정화)
- QR 연타 방지(클라 2~3초 디바운스 + 트랜잭션에서 상태 검증)
- 방 나가기/중도 이탈 처리(joinStatus=left)
- 에러 토스트/재시도 UX(네트워크 실패)

## 핵심 유즈케이스별 “Done 정의” 체크
### 체포 플로우 DoD
- 경찰이 스캔 → 즉시 “체포 성공” 피드백
- 도둑이 자동으로 수감 상태 전환
- counts(남은 도둑) 감소가 경찰 화면에 반영
### 구출 플로우 DoD
- 도둑이 감옥에서 스캔 → 대상 1명만 자유 전환
- 구출자 보너스 점수 반영
### 열쇠 DoD
- 열쇠 1회성 보장
- 사용 즉시 경찰 전체 팝업 발생(한 번만)