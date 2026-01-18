import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:catchrun/core/models/game_model.dart';
import 'package:catchrun/core/models/participant_model.dart';
import 'package:catchrun/core/models/user_model.dart';
import 'package:catchrun/core/network/connectivity_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gameRepositoryProvider = Provider((ref) => GameRepository(
  FirebaseFirestore.instance,
  ref.watch(connectivityServiceProvider),
));

class GameRepository {
  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivityService;

  GameRepository(this._firestore, this._connectivityService);

  // 게임 생성
  Future<String> createGame({
    required String title,
    required GameRule rule,
    required AppUser host,
    int durationSec = 600,
  }) async {
    await _connectivityService.ensureConnection();

    final gameId = _firestore.collection('games').doc().id;
    final gameCode = _generateRandomCode(9);
    final inviteCode = _generateRandomCode(6);
    final joinQrToken = _generateRandomCode(16);

    final game = GameModel(
      id: gameId,
      title: title,
      hostUid: host.uid,
      gameCode: gameCode,
      inviteCode: inviteCode,
      joinQrToken: joinQrToken,
      status: GameStatus.lobby,
      createdAt: DateTime.now(),
      durationSec: durationSec,
      rule: rule,

      counts: GameCounts(
        total: 1,
        robbers: rule.robbersCount,
        cops: rule.copsCount,
        robbersFree: 0, // 게임 시작 전에는 0
        robbersJailed: 0,
      ),
      keyItem: GameKeyItem(
        nfcKeyId: _generateRandomCode(9),
      ),
    );

    final hostParticipant = ParticipantModel(
      uid: host.uid,
      nicknameSnapshot: host.nickname ?? '익명',
      avatarSeedSnapshot: host.avatarSeed,
      joinedAt: DateTime.now(),
      stats: ParticipantStats(),
    );

    await _firestore.runTransaction((transaction) async {
      // 1. gameCodes 매핑 저장
      transaction.set(
        _firestore.collection('gameCodes').doc(gameCode),
        {
          'gameId': gameId,
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
        },
      );

      // 2. 게임 문서 저장
      transaction.set(_firestore.collection('games').doc(gameId), game.toMap());

      // 3. 방장 참가자 추가
      transaction.set(
        _firestore.collection('games').doc(gameId).collection('participants').doc(host.uid),
        hostParticipant.toMap(),
      );
    });

    return gameId;
  }

  // 게임 참가 (코드로 참가)
  Future<String> joinGameByCode({
    required String gameCode,
    required String inviteCode,
    required AppUser user,
  }) async {
    await _connectivityService.ensureConnection();
    // 1. gameCode로 gameId 조회
    final codeDoc = await _firestore.collection('gameCodes').doc(gameCode).get();
    if (!codeDoc.exists) {
      throw Exception('존재하지 않는 게임 번호입니다.');
    }

    final gameId = codeDoc.data()?['gameId'] as String;

    // 2. 트랜잭션으로 참가 처리
    await _firestore.runTransaction((transaction) async {
      final gameDoc = await transaction.get(_firestore.collection('games').doc(gameId));
      if (!gameDoc.exists) throw Exception('게임을 찾을 수 없습니다.');

      final gameData = gameDoc.data()!;
      if (gameData['inviteCode'] != inviteCode) {
        throw Exception('초대 코드가 일치하지 않습니다.');
      }

      if (gameData['status'] != 'lobby') {
        throw Exception('이미 시작되었거나 종료된 게임입니다.');
      }

      final participantRef = _firestore
          .collection('games')
          .doc(gameId)
          .collection('participants')
          .doc(user.uid);
      
      final participantDoc = await transaction.get(participantRef);
      if (participantDoc.exists) {
        // 이미 참가 중이면 성공으로 간주하고 중단
        return;
      }

      // 참가자 추가
      final participant = ParticipantModel(
        uid: user.uid,
        nicknameSnapshot: user.nickname ?? '익명',
        avatarSeedSnapshot: user.avatarSeed,
        joinedAt: DateTime.now(),
        stats: ParticipantStats(),
      );

      transaction.set(participantRef, participant.toMap());

      // 인원수 업데이트
      transaction.update(_firestore.collection('games').doc(gameId), {
        'counts.total': FieldValue.increment(1),
      });

      // 입장 이벤트 기록
      final eventRef = _firestore.collection('games').doc(gameId).collection('events').doc();
      transaction.set(eventRef, {
        'type': 'PLAYER_JOINED',
        'createdAt': FieldValue.serverTimestamp(),
        'actorUid': user.uid,
        'audience': 'all',
        'payload': {
          'nickname': user.nickname ?? '익명',
          'message': '${user.nickname ?? '익명'}님이 입장했습니다.',
        },
      });
    });

    return gameId;
  }

  // 게임 참가 (QR로 참가)
  Future<String> joinGameByQr({
    required String gameId,
    required String qrToken,
    required AppUser user,
  }) async {
    await _connectivityService.ensureConnection();
    await _firestore.runTransaction((transaction) async {
      final gameDoc = await transaction.get(_firestore.collection('games').doc(gameId));
      if (!gameDoc.exists) throw Exception('게임을 찾을 수 없습니다.');

      final gameData = gameDoc.data()!;
      if (gameData['joinQrToken'] != qrToken) {
        throw Exception('유효하지 않은 QR 코드입니다.');
      }

      if (gameData['status'] != 'lobby') {
        throw Exception('이미 시작되었거나 종료된 게임입니다.');
      }

      final participantRef = _firestore
          .collection('games')
          .doc(gameId)
          .collection('participants')
          .doc(user.uid);
      
      final participantDoc = await transaction.get(participantRef);
      if (participantDoc.exists) return;

      final participant = ParticipantModel(
        uid: user.uid,
        nicknameSnapshot: user.nickname ?? '익명',
        avatarSeedSnapshot: user.avatarSeed,
        joinedAt: DateTime.now(),
        stats: ParticipantStats(),
      );

      transaction.set(participantRef, participant.toMap());
      transaction.update(_firestore.collection('games').doc(gameId), {
        'counts.total': FieldValue.increment(1),
      });

      // 입장 이벤트 기록
      final eventRef = _firestore.collection('games').doc(gameId).collection('events').doc();
      transaction.set(eventRef, {
        'type': 'PLAYER_JOINED',
        'createdAt': FieldValue.serverTimestamp(),
        'actorUid': user.uid,
        'audience': 'all',
        'payload': {
          'nickname': user.nickname ?? '익명',
          'message': '${user.nickname ?? '익명'}님이 입장했습니다.',
        },
      });
    });

    return gameId;
  }

  // 게임 참가 (NFC 열쇠로 참가 - Deep Link)
  Future<String> joinGameByNfcKey({
    required String gameId,
    required String nfcKeyId,
    required AppUser user,
  }) async {
    await _connectivityService.ensureConnection();
    await _firestore.runTransaction((transaction) async {
      final gameDoc = await transaction.get(_firestore.collection('games').doc(gameId));
      if (!gameDoc.exists) throw Exception('게임을 찾을 수 없습니다.');

      final gameData = gameDoc.data()!;
      if (gameData['keyItem']['nfcKeyId'] != nfcKeyId) {
        throw Exception('유효하지 않은 보안 열쇠입니다.');
      }

      if (gameData['status'] != 'lobby') {
        throw Exception('이미 시작되었거나 종료된 게임입니다.');
      }

      final participantRef = _firestore
          .collection('games')
          .doc(gameId)
          .collection('participants')
          .doc(user.uid);
      
      final participantDoc = await transaction.get(participantRef);
      if (participantDoc.exists) return;

      final participant = ParticipantModel(
        uid: user.uid,
        nicknameSnapshot: user.nickname ?? '익명',
        avatarSeedSnapshot: user.avatarSeed,
        joinedAt: DateTime.now(),
        stats: ParticipantStats(),
      );

      transaction.set(participantRef, participant.toMap());
      transaction.update(_firestore.collection('games').doc(gameId), {
        'counts.total': FieldValue.increment(1),
      });

      // 입장 이벤트 기록
      final eventRef = _firestore.collection('games').doc(gameId).collection('events').doc();
      transaction.set(eventRef, {
        'type': 'PLAYER_JOINED',
        'createdAt': FieldValue.serverTimestamp(),
        'actorUid': user.uid,
        'audience': 'all',
        'payload': {
          'nickname': user.nickname ?? '익명',
          'message': '${user.nickname ?? '익명'}님이 입장했습니다.',
        },
      });
    });

    return gameId;
  }

  // 게임 정보 스트림
  Stream<GameModel?> watchGame(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .snapshots()
        .map((snapshot) => snapshot.exists 
            ? GameModel.fromMap(snapshot.data()!, snapshot.id) 
            : null);
  }

  // 참가자 역할 업데이트 (방장 권한)
  Future<void> updateParticipantRole({
    required String gameId,
    required String uid,
    required ParticipantRole role,
  }) async {
    await _firestore
        .collection('games')
        .doc(gameId)
        .collection('participants')
        .doc(uid)
        .update({
      'role': role.name,
    });
  }

  // 게임 시작
  Future<void> startGame(String gameId) async {
    await _connectivityService.ensureConnection();
    await _firestore.runTransaction((transaction) async {
      final gameRef = _firestore.collection('games').doc(gameId);
      final gameDoc = await transaction.get(gameRef);
      if (!gameDoc.exists) return;

      final gameData = gameDoc.data()!;
      if (gameData['status'] != 'lobby') return;

      final now = DateTime.now();
      final durationSec = gameData['durationSec'] ?? 600;
      final endsAt = now.add(Duration(seconds: durationSec));

      // 1. 실제 참가자 기반 인원수 재계산
      final participantsSnapshot = await gameRef.collection('participants').get();
      final participants = participantsSnapshot.docs
          .map((doc) => ParticipantModel.fromMap(doc.data(), doc.id))
          .toList();

      final cops = participants.where((p) => p.role == ParticipantRole.cop).length;
      final robbers = participants.where((p) => p.role == ParticipantRole.robber).length;

      // 2. 게임 상태 및 카운트 업데이트
      transaction.update(gameRef, {
        'status': 'playing',
        'startedAt': FieldValue.serverTimestamp(),
        'endsAt': Timestamp.fromDate(endsAt),
        'counts.cops': cops,
        'counts.robbers': robbers,
        'counts.robbersFree': robbers,
        'counts.robbersJailed': 0,
      });

      // 2.5 모든 참가자의 lastStateChangedAt 초기화
      for (final doc in participantsSnapshot.docs) {
        transaction.update(doc.reference, {
          'lastStateChangedAt': FieldValue.serverTimestamp(),
        });
      }


      // 3. 시작 이벤트 기록
      final eventRef = gameRef.collection('events').doc();
      transaction.set(eventRef, {
        'type': 'GAME_STARTED',
        'createdAt': FieldValue.serverTimestamp(),
        'actorUid': gameData['hostUid'],
        'audience': 'all',
        'payload': {
          'message': '게임이 시작되었습니다! 달리세요!',
          'durationMs': 3000,
        },
      });
    });
  }

  // 내부 공통 종료 로직 (반드시 트랜잭션 내에서 호출)
  Future<void> _finishGameInternal({
    required Transaction transaction,
    required DocumentReference gameRef,
    required Map<String, dynamic> gameData,
    required DateTime now,
    Duration serverTimeOffset = Duration.zero,
  }) async {
    // 1. 모든 참가자 정보를 가져와서 승리 판정 및 점수 정산
    final participantsSnapshot = await gameRef.collection('participants').get();
    final participants = participantsSnapshot.docs
        .map((doc) => ParticipantModel.fromMap(doc.data(), doc.id))
        .toList();


    final counts = gameData['counts'] as Map<String, dynamic>?;
    final robbersFree = counts?['robbersFree'] as int? ?? 0;
    
    // 도둑이 한 명도 안 남았으면 경찰 승리, 아니면 도둑 승리
    final winnerRole = (robbersFree == 0) ? ParticipantRole.cop : ParticipantRole.robber;

    // 2. 각 참가자 최종 점수 정산 (도둑 생존 점수 등)
    for (final p in participants) {
      if (p.role == ParticipantRole.robber) {
        int addedSurvivalSec = 0;
        if (p.state == RobberState.free) {
          final lastChanged = p.lastStateChangedAt ?? (gameData['startedAt'] as Timestamp?)?.toDate() ?? now;
          addedSurvivalSec = max(0, now.difference(lastChanged).inSeconds);
        }
        
        final finalSurvivalSec = p.stats.survivalSec + addedSurvivalSec;
        final survivalScore = finalSurvivalSec; 

        transaction.update(gameRef.collection('participants').doc(p.uid), {
          'stats.survivalSec': finalSurvivalSec,
          'score': FieldValue.increment(survivalScore),
          'lastStateChangedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // 3. 게임 상태 업데이트
    transaction.update(gameRef, {
      'status': 'finished',
      'finishedAt': FieldValue.serverTimestamp(),
      'winnerRole': winnerRole.name,
    });

    // 4. 종료 이벤트 기록
    final eventRef = gameRef.collection('events').doc();
    transaction.set(eventRef, {
      'type': 'GAME_ENDED',
      'createdAt': FieldValue.serverTimestamp(),
      'actorUid': gameData['hostUid'],
      'audience': 'all',
      'payload': {
        'message': '게임이 종료되었습니다! ${winnerRole == ParticipantRole.cop ? "경찰" : "도둑"} 승리!',
        'winnerRole': winnerRole.name,
        'durationMs': 3000,
      },
    });
  }


  // 게임 종료
  // 게임 종료 (분산 검증 대응: 누구나 호출 가능하지만 최초 1인만 성공)
  Future<void> finishGame(String gameId, {Duration serverTimeOffset = Duration.zero}) async {
    await _connectivityService.ensureConnection();
    
    // 1. [First-order Check] 트랜잭션 진입 전 상태를 먼저 체크하여 불필요한 부하 방지
    final gameDocBefore = await _firestore.collection('games').doc(gameId).get();
    if (!gameDocBefore.exists || gameDocBefore.data()?['status'] != 'playing') {
      return;
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final gameRef = _firestore.collection('games').doc(gameId);
        final gameDoc = await transaction.get(gameRef);
        if (!gameDoc.exists) return;

        final gameData = gameDoc.data()!;
        
        // 2. [Atomic Verifier] 트랜잭션 내에서 원자적으로 상태 재호출 및 검증 (멱등성 보장)
        if (gameData['status'] != 'playing') return;

        await _finishGameInternal(
          transaction: transaction,
          gameRef: gameRef,
          gameData: gameData,
          now: getEstimatedServerTime(serverTimeOffset),
          serverTimeOffset: serverTimeOffset,
        );
      });
    } catch (e) {
      // 다른 클라이언트가 동시에 성공하여 충돌이 발생한 경우 조용히 리턴
      if (e.toString().contains('ABORTED') || e.toString().contains('failed-precondition')) {
        return;
      }
      rethrow;
    }
  }


  // 게임 나가기
  Future<void> leaveGame({
    required String gameId,
    required String uid,
  }) async {
    await _connectivityService.ensureConnection();
    await _firestore.runTransaction((transaction) async {
      final gameRef = _firestore.collection('games').doc(gameId);
      final participantRef = gameRef.collection('participants').doc(uid);

      final gameDoc = await transaction.get(gameRef);
      if (!gameDoc.exists) return;

      final participantDoc = await transaction.get(participantRef);
      if (!participantDoc.exists) return;

      final gameData = gameDoc.data()!;
      final isHost = gameData['hostUid'] == uid;

      // 1. 참가자 삭제
      transaction.delete(participantRef);

      // 2. 인원수 업데이트
      transaction.update(gameRef, {
        'counts.total': FieldValue.increment(-1),
      });

      // 퇴장 이벤트 기록
      final eventRef = gameRef.collection('events').doc();
      transaction.set(eventRef, {
        'type': 'PLAYER_LEFT',
        'createdAt': FieldValue.serverTimestamp(),
        'actorUid': uid,
        'audience': 'all',
        'payload': {
          'nickname': (participantDoc.data())?['nicknameSnapshot'] ?? '익명',
          'message': '${(participantDoc.data())?['nicknameSnapshot'] ?? '익명'}님이 퇴장했습니다.',
        },
      });

      // 3. 방장이 나가는 경우 처리
      if (isHost) {
        // 방장이 나가면 게임을 종료 상태로 변경 (또는 무효화)
        transaction.update(gameRef, {'status': 'finished'});
        
        // 더 이상 참가할 수 없도록 입장 코드 매핑 삭제
        final gameCode = gameData['gameCode'] as String?;
        if (gameCode != null) {
          transaction.delete(_firestore.collection('gameCodes').doc(gameCode));
        }
      }
    });
  }

  // 강퇴하기
  Future<void> kickParticipant({
    required String gameId,
    required String uid,
  }) async {
    await _connectivityService.ensureConnection();
    await _firestore.runTransaction((transaction) async {
      final gameRef = _firestore.collection('games').doc(gameId);
      final participantRef = gameRef.collection('participants').doc(uid);

      final gameDoc = await transaction.get(gameRef);
      if (!gameDoc.exists) return;

      final participantDoc = await transaction.get(participantRef);
      if (!participantDoc.exists) return;

      final participantData = participantDoc.data()!;
      final nickname = participantData['nicknameSnapshot'] ?? '익명';

      // 1. 참가자 삭제
      transaction.delete(participantRef);

      // 2. 인원수 업데이트
      transaction.update(gameRef, {
        'counts.total': FieldValue.increment(-1),
      });

      // 3. 강퇴 이벤트 기록
      final eventRef = gameRef.collection('events').doc();
      transaction.set(eventRef, {
        'type': 'PLAYER_KICKED',
        'createdAt': FieldValue.serverTimestamp(),
        'actorUid': gameDoc.data()?['hostUid'],
        'targetUid': uid,
        'audience': 'all',
        'payload': {
          'nickname': nickname,
          'message': '$nickname님이 방장에 의해 강퇴되었습니다.',
        },
      });
    });
  }

  // 체포하기
  Future<void> catchRobber({
    required String gameId,
    required String copUid,
    required String robberUid,
    Duration serverTimeOffset = Duration.zero,
  }) async {
    await _connectivityService.ensureConnection();
    await _firestore.runTransaction((transaction) async {
      final gameRef = _firestore.collection('games').doc(gameId);
      final copRef = gameRef.collection('participants').doc(copUid);
      final robberRef = gameRef.collection('participants').doc(robberUid);

      final gameDoc = await transaction.get(gameRef);
      final copDoc = await transaction.get(copRef);
      final robberDoc = await transaction.get(robberRef);

      if (!gameDoc.exists || !copDoc.exists || !robberDoc.exists) return;

      final robberData = ParticipantModel.fromMap(robberDoc.data()!, robberUid);
      if (robberData.role != ParticipantRole.robber) {
        throw Exception('도둑이 아닙니다.');
      }
      if (robberData.state == RobberState.jailed) {
        throw Exception('이미 체포된 도둑입니다.');
      }


      final now = getEstimatedServerTime(serverTimeOffset);
      final lastChanged = robberData.lastStateChangedAt ?? (gameDoc.data()!['startedAt'] as Timestamp?)?.toDate() ?? now;
      final addedSurvivalSec = max(0, now.difference(lastChanged).inSeconds);

      // 1. 도둑 상태 업데이트
      transaction.update(robberRef, {
        'state': RobberState.jailed.name,
        'jailedAt': FieldValue.serverTimestamp(),
        'lastStateChangedAt': FieldValue.serverTimestamp(),
        'stats.survivalSec': FieldValue.increment(addedSurvivalSec),
        'updatedAt': FieldValue.serverTimestamp(),
      });


      // 2. 경찰 통계 및 점수 업데이트
      transaction.update(copRef, {
        'stats.catches': FieldValue.increment(1),
        'score': FieldValue.increment(100), // 체포 점수: 100
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. 게임 카운트 업데이트
      transaction.update(gameRef, {
        'counts.robbersFree': FieldValue.increment(-1),
        'counts.robbersJailed': FieldValue.increment(1),
      });

      // 4. 상세 CAUGHT 이벤트 기록
      final eventRef = gameRef.collection('events').doc();
      final copNickname = (copDoc.data())?['nicknameSnapshot'] ?? '경찰';
      final robberNickname = (robberDoc.data())?['nicknameSnapshot'] ?? '도둑';

      transaction.set(eventRef, {
        'type': 'CAUGHT',
        'createdAt': FieldValue.serverTimestamp(),
        'actorUid': copUid,
        'targetUid': robberUid,
        'audience': 'all',
        'payload': {
          'actorNickname': copNickname,
          'targetNickname': robberNickname,
          'message': '경찰 $copNickname님이 도둑 $robberNickname님을 체포했습니다!',
        },
      });

      // 5. 마지막 도둑이었는지 확인하여 자동 종료 (백엔드 성격의 트랜잭션 로직)
      final counts = (gameDoc.data()!['counts'] as Map<String, dynamic>);
      if (counts['robbersFree'] - 1 <= 0) {
        // 모든 도둑이 잡힘 -> 즉시 종료 처리 루틴
        final updatedGameData = Map<String, dynamic>.from(gameDoc.data()!);
        updatedGameData['counts']['robbersFree'] = 0; // 강제로 0으로 설정하여 내부 로직에서 cop 승리로 판정되게 함
        
        await _finishGameInternal(
          transaction: transaction,
          gameRef: gameRef,
          gameData: updatedGameData,
          now: now,
          serverTimeOffset: serverTimeOffset,
        );
      }
    });
  }


  // 구출하기
  Future<void> rescueRobber({
    required String gameId,
    required String rescuerUid,
    required String jailedUid,
  }) async {
    await _connectivityService.ensureConnection();
    await _firestore.runTransaction((transaction) async {
      final gameRef = _firestore.collection('games').doc(gameId);
      final rescuerRef = gameRef.collection('participants').doc(rescuerUid);
      final jailedRef = gameRef.collection('participants').doc(jailedUid);

      final gameDoc = await transaction.get(gameRef);
      final rescuerDoc = await transaction.get(rescuerRef);
      final jailedDoc = await transaction.get(jailedRef);

      if (!gameDoc.exists || !rescuerDoc.exists || !jailedDoc.exists) return;

      final rescuerData = ParticipantModel.fromMap(rescuerDoc.data()!, rescuerUid);
      final jailedData = ParticipantModel.fromMap(jailedDoc.data()!, jailedUid);

      if (jailedData.state != RobberState.jailed) {
        throw Exception('이미 자유 상태인 도둑입니다.');
      }


      // 구출 제한 체크 (열쇠 사용 후 5분간)
      if (rescuerData.rescueDisabledUntil != null && 
          rescuerData.rescueDisabledUntil!.isAfter(DateTime.now())) {
        throw Exception('열쇠 사용 후에는 잠시 동안 다른 도둑을 구출할 수 없습니다.');
      }

      // 1. 도둑 상태 업데이트
      transaction.update(jailedRef, {
        'state': RobberState.free.name,
        'releasedAt': FieldValue.serverTimestamp(),
        'lastStateChangedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });


      // 2. 구출자 통계 및 점수 업데이트
      transaction.update(rescuerRef, {
        'stats.rescues': FieldValue.increment(1),
        'score': FieldValue.increment(50), // 구출 점수: 50
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. 게임 카운트 업데이트
      transaction.update(gameRef, {
        'counts.robbersFree': FieldValue.increment(1),
        'counts.robbersJailed': FieldValue.increment(-1),
      });

      // 4. 상세 RESCUED 이벤트 기록
      final eventRef = gameRef.collection('events').doc();
      final rescuerNickname = (rescuerDoc.data())?['nicknameSnapshot'] ?? '도둑';
      final jailedNickname = (jailedDoc.data())?['nicknameSnapshot'] ?? '도둑';

      transaction.set(eventRef, {
        'type': 'RESCUED',
        'createdAt': FieldValue.serverTimestamp(),
        'actorUid': rescuerUid,
        'targetUid': jailedUid,
        'audience': 'all',
        'payload': {
          'actorNickname': rescuerNickname,
          'targetNickname': jailedNickname,
          'message': '도둑 $rescuerNickname님이 $jailedNickname님을 구출했습니다!',
        },
      });
    });
  }

  // NFC 열쇠 사용하기
  Future<void> usePrisonKey({
    required String gameId,
    required String uid,
    required String scannedId,
    Duration serverTimeOffset = Duration.zero,
  }) async {
    await _connectivityService.ensureConnection();
    await _firestore.runTransaction((transaction) async {
      final gameRef = _firestore.collection('games').doc(gameId);
      final participantRef = gameRef.collection('participants').doc(uid);

      final gameDoc = await transaction.get(gameRef);
      final participantDoc = await transaction.get(participantRef);

      if (!gameDoc.exists || !participantDoc.exists) return;

      final game = GameModel.fromMap(gameDoc.data()!, gameId);
      final participant = ParticipantModel.fromMap(participantDoc.data()!, uid);

      if (participant.state != RobberState.jailed) return;
      if (game.keyItem.usedByUid != null) {
        throw Exception('이미 사용된 열쇠입니다.');
      }
      if (game.keyItem.nfcKeyId != scannedId) {
        throw Exception('유효하지 않은 열쇠입니다.');
      }

      final now = getEstimatedServerTime(serverTimeOffset);
      final rescueDisabledUntil = now.add(const Duration(minutes: 5));

      // 1. 도둑 상태 업데이트 (자유 상태 + 구출 제한 + 점수 차감)
      transaction.update(participantRef, {
        'state': RobberState.free.name,
        'releasedAt': FieldValue.serverTimestamp(),
        'rescueDisabledUntil': Timestamp.fromDate(rescueDisabledUntil),
        'lastStateChangedAt': FieldValue.serverTimestamp(),
        'stats.keyUsed': true,
        'score': FieldValue.increment(-70), // 열쇠 사용 점수 차감: -70
        'updatedAt': FieldValue.serverTimestamp(),
      });


      // 2. 게임 상태 업데이트 (열쇠 사용 기록 + 카운트)
      transaction.update(gameRef, {
        'keyItem.usedByUid': uid,
        'keyItem.usedAt': FieldValue.serverTimestamp(),
        'counts.robbersFree': FieldValue.increment(1),
        'counts.robbersJailed': FieldValue.increment(-1),
      });

      // 3. KEY_USED 이벤트 기록 (경찰 등에게 알림)
      final eventRef = gameRef.collection('events').doc();
      final nickname = (participantDoc.data())?['nicknameSnapshot'] ?? '도둑';

      transaction.set(eventRef, {
        'type': 'KEY_USED',
        'createdAt': FieldValue.serverTimestamp(),
        'actorUid': uid,
        'audience': 'all',
        'payload': {
          'actorNickname': nickname,
          'message': '열쇠 사용됨! 도둑 $nickname님이 탈출했습니다!',
          'durationMs': 3000,
        },
      });
    });
  }

  // 실시간 이벤트 감시 (팝업용 - 최신 1개)
  Stream<Map<String, dynamic>?> watchLatestEvent(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .collection('events')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return data;
    });
  }

  // 실시간 모든 이벤트 감시 (로그용)
  Stream<List<Map<String, dynamic>>> watchAllEvents(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  // 참가자 목록 스트림
  Stream<List<ParticipantModel>> watchParticipants(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .collection('participants')
        .orderBy('joinedAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ParticipantModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  String _generateRandomCode(int length) {
    const chars = '0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }

  /// 서버 시간과 로컬 시간의 offset을 계산합니다.
  /// 이를 통해 기기마다 다른 시스템 시간에도 동기화된 타이머를 구현할 수 있습니다.
  Future<Duration> calculateServerTimeOffset() async {
    DocumentReference? docRef;
    
    try {
      await _connectivityService.ensureConnection();
      final localBefore = DateTime.now();
      
      // Firestore에 더미 문서를 작성하여 서버 타임스탬프 획득
      docRef = _firestore.collection('_timesync').doc();
      
      // 타임아웃 설정 (5초)
      await docRef.set({
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Server time sync timeout'),
      );
      
      // 작성된 문서를 읽어서 서버 타임스탬프 확인
      final doc = await docRef.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Server time sync timeout'),
      );
      
      final data = doc.data() as Map<String, dynamic>?;
      final serverTime = (data?['createdAt'] as Timestamp?)?.toDate();
      
      if (serverTime == null) {
        return Duration.zero;
      }
      
      final localAfter = DateTime.now();
      // 네트워크 왕복 시간의 절반을 보정
      final estimatedLocalTime = localBefore.add(
        Duration(milliseconds: localAfter.difference(localBefore).inMilliseconds ~/ 2)
      );
      
      // offset = 서버 시간 - 로컬 시간
      return serverTime.difference(estimatedLocalTime);
    } catch (e) {
      // 네트워크 오류, Firestore 접근 실패, 타임아웃 등의 경우
      // Duration.zero를 반환하여 로컬 시간을 사용하도록 fallback
      return Duration.zero;
    } finally {
      // 더미 문서 삭제 (실패해도 무시)
      if (docRef != null) {
        try {
          await docRef.delete().timeout(const Duration(seconds: 3));
        } catch (_) {
          // 문서 삭제 실패는 무시 (자동으로 정리될 것임)
        }
      }
    }
  }

  /// offset을 적용하여 현재 추정 서버 시간을 반환합니다.
  DateTime getEstimatedServerTime(Duration offset) {
    return DateTime.now().add(offset);
  }
}
