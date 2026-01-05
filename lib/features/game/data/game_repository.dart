import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:catchrun/core/models/game_model.dart';
import 'package:catchrun/core/models/participant_model.dart';
import 'package:catchrun/core/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gameRepositoryProvider = Provider((ref) => GameRepository(FirebaseFirestore.instance));

class GameRepository {
  final FirebaseFirestore _firestore;

  GameRepository(this._firestore);

  // 게임 생성
  Future<String> createGame({
    required String title,
    required GameRule rule,
    required AppUser host,
  }) async {
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
      rule: rule,
      counts: GameCounts(
        total: 1,
        robbers: rule.robbersCount,
        cops: rule.copsCount,
        robbersFree: 0, // 게임 시작 전에는 0
        robbersJailed: 0,
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
    });

    return gameId;
  }

  // 게임 참가 (QR로 참가)
  Future<String> joinGameByQr({
    required String gameId,
    required String qrToken,
    required AppUser user,
  }) async {
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
    await _firestore.runTransaction((transaction) async {
      final gameRef = _firestore.collection('games').doc(gameId);
      final gameDoc = await transaction.get(gameRef);
      if (!gameDoc.exists) return;

      final gameData = gameDoc.data()!;
      if (gameData['status'] != 'lobby') return;

      final now = DateTime.now();
      final durationSec = gameData['durationSec'] ?? 600;
      final endsAt = now.add(Duration(seconds: durationSec));

      // 1. 게임 상태 업데이트
      transaction.update(gameRef, {
        'status': 'playing',
        'startedAt': FieldValue.serverTimestamp(),
        'endsAt': Timestamp.fromDate(endsAt),
      });

      // 2. 시작 이벤트 기록
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

  // 게임 종료
  Future<void> finishGame(String gameId) async {
    await _firestore.runTransaction((transaction) async {
      final gameRef = _firestore.collection('games').doc(gameId);
      final gameDoc = await transaction.get(gameRef);
      if (!gameDoc.exists) return;

      final gameData = gameDoc.data()!;
      if (gameData['status'] != 'playing') return;

      // 1. 상태 업데이트
      transaction.update(gameRef, {
        'status': 'finished',
        'finishedAt': FieldValue.serverTimestamp(),
      });

      // 2. 종료 이벤트 기록
      final eventRef = gameRef.collection('events').doc();
      transaction.set(eventRef, {
        'type': 'GAME_ENDED',
        'createdAt': FieldValue.serverTimestamp(),
        'actorUid': gameData['hostUid'],
        'audience': 'all',
        'payload': {
          'message': '게임이 종료되었습니다! 결과를 확인하세요.',
          'durationMs': 3000,
        },
      });
    });
  }

  // 게임 나가기
  Future<void> leaveGame({
    required String gameId,
    required String uid,
  }) async {
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
}
