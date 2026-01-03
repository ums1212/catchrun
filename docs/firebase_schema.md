### 1) 컬렉션 구조 요약
/users/{uid}
/games/{gameId}
/participants/{uid}
/events/{eventId}
/scans/{scanId}           (선택: QR/NFC 판정 로그)
/gameCodes/{gameCode9}      (입장 코드 -> gameId 매핑)

### 2) users
`/users/{uid}`
유저 프로필(로그인 후 1회 생성/업데이트)
```json
{
  "uid": "firebase uid",
  "nickname": "랜덤닉네임",
  "avatarSeed": 12345,
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```
`avatarSeed`: 추후 프리셋 변경 시에도 기본값 생성에 사용 가능

### 3) gameCodes (9자리 게임번호 매핑)
`/gameCodes/{gameCode9}`
게임 번호(9자리)를 문서 ID로 사용 (예: "481920374")
```json
{
  "gameId": "games/{gameId}의 ID",
  "createdAt": "serverTimestamp",
  "expiresAt": "timestamp(예: 생성 후 24h)"
}
```
- 참가 흐름:
    - 사용자가 9자리 입력 → gameCodes/{code} 조회 → gameId 획득 → games/{gameId} 접근
- 만료를 두면 코드 충돌/재사용 관리가 쉬움(Cloud Functions로 정리 가능)

### 4) games (핵심)
`/games/{gameId}`
게임(방) 메타 + 진행 상태
```json
{
  "title": "우리동네 한판",
  "hostUid": "방장 uid",

  "gameCode": "9자리 숫자 문자열",
  "inviteCode": "6자리 숫자 문자열",

  "joinQrToken": "랜덤 토큰(입장용 QR에 인코딩)",
  "joinQrEnabled": true,

  "status": "lobby | playing | finished",
  "createdAt": "serverTimestamp",
  "startedAt": "timestamp|null",
  "endsAt": "timestamp|null",
  "durationSec": 600,

  "rule": {
    "useQr": true,
    "useNfc": true,
    "copsCount": 2,
    "robbersCount": 6,
    "autoAssignRoles": true
  },

  "counts": {
    "total": 8,
    "cops": 2,
    "robbers": 6,
    "robbersFree": 6,
    "robbersJailed": 0
  },

  "prison": {
    "enabled": true,
    "name": "감옥",
    "geo": { "lat": 37.0, "lng": 127.0 },   // 선택
    "radiusM": 20,                          // 선택
    "strictLock": true                      // 수감자는 감옥 밖 이동 불가 정책
  },

  "keyItem": {
    "enabled": true,
    "nfcKeyId": "physical_key_001",          // NFC 태그 ID 또는 내부 키 ID
    "usedByUid": null,
    "usedAt": null,
    "cooldownSec": 300                       // 사용자는 5분간 구출 불가
  },

  "score": {
    "copCatch": 50,
    "robberSurvivalPerMin": 10,
    "robberRescueBonus": 30,
    "itemCost": 20
  }
}
```
- status 값
  - lobby: 대기방
  - playing: 게임 진행
  - finished: 종료(결과 확정)

### 5) participants (게임 참가자)
`/games/{gameId}/participants/{uid}`
각 참가자의 상태/점수/통계 (리더보드, 칭호 계산 기반)
```json
{
  "uid": "참가자 uid",
  "nicknameSnapshot": "게임 당시 닉네임",
  "avatarSeedSnapshot": 12345,

  "joinStatus": "joined | left | kicked",
  "joinedAt": "serverTimestamp",

  "role": "cop | robber",
  "roleLock": false,                 // 방장이 고정하면 true
  "wantsCop": false,                 // '경찰 지원' 버튼 상태

  "state": "free | jailed",          // 도둑만 사용 (경찰은 free 고정)
  "jailedAt": null,
  "releasedAt": null,

  "constraints": {
    "rescueDisabledUntil": null       // 감옥 열쇠 사용한 도둑: now + 5min
  },

  "score": 0,
  "stats": {
    "catches": 0,                     // 경찰용
    "rescues": 0,                     // 도둑용(구출 수행)
    "survivalSec": 0,                 // 도둑 생존 누적(집계용)
    "keyUsed": false                  // 감옥 열쇠 사용 여부
  },

  "updatedAt": "serverTimestamp"
}
```
“남은 도둑 수/전체 도둑 수”는 `games.counts.robbersFree/robbers`로 바로 표시 가능.

### 6) events (실시간 팝업/알림용)
`/games/{gameId}/events/{eventId}`
게임 내 이벤트 스트림(클라이언트가 실시간 구독)
```json
{
  "type": "KEY_USED | CAUGHT | RESCUED | GAME_STARTED | GAME_ENDED",
  "createdAt": "serverTimestamp",

  "actorUid": "행동한 사람 uid",
  "targetUid": "대상 uid|null",

  "payload": {
    "message": "열쇠 사용됨! 도둑 탈출!",
    "durationMs": 2500
  },

  "audience": "all | cops | robbers"
}
```
“감옥 열쇠 사용됨! 도둑 탈출!” 팝업은 `type=KEY_USED`, `audience=cops`, `payload.message`로 처리하면 깔끔합니다.

### 7) scans (선택: QR/NFC 판정 로그)
판정 분쟁/치팅 분석/리플레이를 위해 추천(없어도 MVP 가능)
`/games/{gameId}/scans/{scanId}`
```json
{
  "type": "QR | NFC",
  "action": "CATCH | RESCUE | KEY",
  "scannerUid": "스캔한 사람 uid",
  "scannedUid": "스캔된 사람 uid|null",
  "nfcKeyId": "physical_key_001|null",
  "createdAt": "serverTimestamp"
}
```

### 8) 핵심 트랜잭션 로직(중요)
Firestore는 “동시성” 때문에 아래 액션은 반드시 Transaction 또는 서버 함수로 처리하는 걸 권장합니다.

#### A. 체포(CATCH)
- 조건:
  - 게임 `status=playing`
  - 스캐너(경찰) role=cop
  - 대상(도둑) role=robber, state=free
- 처리(트랜잭션):
  - 대상 participant.state `free -> jailed`, `jailedAt=now`
  - 경찰 stats.catches +1, score + `copCatch`
  - games.counts.robbersFree -1, robbersJailed +1
  - events에 `CAUGHT` 추가
#### B. 구출(RESCUE)
- 조건:
  - 구출자 role=robber, state=free
  - 구출자 rescueDisabledUntil == null or now 이후
  - 대상 role=robber, state=jailed
- 처리:
  - 대상 `jailed -> free`, `releasedAt=now`
  - 구출자 stats.rescues +1, score + rescueBonus
  - games.counts.robbersFree +1, robbersJailed -1
  - events에 `RESCUED`
#### C. 감옥 열쇠(KEY)
- 조건:
  - actor role=robber, state=jailed
  - games.keyItem.usedByUid == null (1회성)
- 처리:
  - actor `jailed -> free`
  - actor.constraints.rescueDisabledUntil = now + 300s
  - actor.stats.keyUsed = true
  - games.keyItem.usedByUid = actorUid, usedAt=now
  - counts 업데이트(+1/-1)
  - events: `KEY_USED` (audience=cops, 전체화면 팝업)