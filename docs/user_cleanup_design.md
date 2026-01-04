# 🧹 유령 회원 자동 삭제 시스템 설계 (User Cleanup)

가입 절차(구글 로그인)는 마쳤으나, 프로필 설정(닉네임 입력)을 완료하지 않은 채 장기간 방치된 사용자 데이터를 자동으로 정리하여 DB 효율성과 보안을 관리합니다.

## 1. 목적
- **데이터 품질 유지**: 가공되지 않은 미완성 사용자 데이터 제거
- **보안 및 프라이버시**: 실제 서비스를 이용하지 않는 사용자의 이메일 등 개인정보 최소화
- **비용 최적화**: 사용하지 않는 Firestore 문서 및 인증 레코드 삭제

## 2. 삭제 대상 정의 (Trigger Condition)
다음 두 조건을 **모두 충족**하는 경우 삭제 대상이 됩니다.
1. **Firestore 프로필 미완성**: `users/{uid}` 문서에서 `nickname` 필드가 `null`이거나 비어있음.
2. **장기 방치**: `createdAt` (가입 시점)이 현재 시간으로부터 **30일 이상** 경과함.

## 3. 구현 방식: Firebase Cloud Functions (Scheduled)

### 3.1 기술 스택
- **Firebase Cloud Functions v2**: Node.js 기반 서버리스 함수
- **Cloud Scheduler (Cron Job)**: 정기적 실행 관리 (예: 매일 새벽 3시)
- **Firebase Admin SDK**: Auth 및 Firestore 통합 관리 권한

### 3.2 프로세스 로직 (Pseudocode)
```javascript
// 매일 새벽 3시에 실행되는 스케줄러 함수
exports.cleanupGhostUsers = onSchedule("0 3 * * *", async (event) => {
  const thirtyDaysAgo = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
  );

  // 1. 조건에 맞는 문서 쿼리
  const snapshot = await admin.firestore().collection('users')
    .where('nickname', '==', null)
    .where('createdAt', '<', thirtyDaysAgo)
    .get();

  if (snapshot.empty) return;

  // 2. 일괄 삭제 처리 (Auth -> Firestore 순서)
  for (const doc of snapshot.docs) {
    const uid = doc.id;
    try {
      // Firebase Auth에서 계정 삭제
      await admin.auth().deleteUser(uid);
      // Firestore 문서 삭제
      await doc.ref.delete();
      console.log(`Successfully deleted ghost user: ${uid}`);
    } catch (error) {
      console.error(`Error deleting user ${uid}:`, error);
    }
  }
});
```

## 4. 고려 사항 (Future Task)
- **알림 발송 (선택)**: 삭제 3일 전, 가입 당시 확보한 이메일로 안내 메일 발송 로직 추가 여부.
- **예외 처리**: 특정 테스트 계정이나 관리자 계정이 삭제되지 않도록 화이트리스트(whitelist) 관리.
- **로그 기록**: 삭제된 사용자 수와 시점을 별도의 `system_logs` 컬렉션에 기록하여 추적 가능하게 함.

---
*이 기능은 MVP 개발 완료 이후 고도화 단계에서 구현할 예정입니다.*
