import 'package:cloud_firestore/cloud_firestore.dart';

enum ParticipantRole {
  cop,
  robber;

  static ParticipantRole fromString(String value) {
    return ParticipantRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ParticipantRole.robber,
    );
  }
}

enum RobberState {
  free,
  jailed;

  static RobberState fromString(String value) {
    return RobberState.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RobberState.free,
    );
  }
}

class ParticipantModel {
  final String uid;
  final String nicknameSnapshot;
  final String? avatarSeedSnapshot;
  final String joinStatus; // joined, left, kicked
  final DateTime joinedAt;
  final ParticipantRole role;
  final bool roleLock;
  final bool wantsCop;
  final RobberState state;
  final DateTime? jailedAt;
  final DateTime? releasedAt;
  final int score;
  final ParticipantStats stats;
  final DateTime? rescueDisabledUntil;

  ParticipantModel({
    required this.uid,
    required this.nicknameSnapshot,
    this.avatarSeedSnapshot,
    this.joinStatus = 'joined',
    required this.joinedAt,
    this.role = ParticipantRole.robber,
    this.roleLock = false,
    this.wantsCop = false,
    this.state = RobberState.free,
    this.jailedAt,
    this.releasedAt,
    this.rescueDisabledUntil,
    this.score = 0,
    required this.stats,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nicknameSnapshot': nicknameSnapshot,
      'avatarSeedSnapshot': avatarSeedSnapshot,
      'joinStatus': joinStatus,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'role': role.name,
      'roleLock': roleLock,
      'wantsCop': wantsCop,
      'state': state.name,
      'jailedAt': jailedAt != null ? Timestamp.fromDate(jailedAt!) : null,
      'releasedAt': releasedAt != null ? Timestamp.fromDate(releasedAt!) : null,
      'rescueDisabledUntil': rescueDisabledUntil != null ? Timestamp.fromDate(rescueDisabledUntil!) : null,
      'score': score,
      'stats': stats.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ParticipantModel.fromMap(Map<String, dynamic> map, String id) {
    return ParticipantModel(
      uid: id,
      nicknameSnapshot: map['nicknameSnapshot'] ?? '',
      avatarSeedSnapshot: map['avatarSeedSnapshot'],
      joinStatus: map['joinStatus'] ?? 'joined',
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: ParticipantRole.fromString(map['role'] ?? 'robber'),
      roleLock: map['roleLock'] ?? false,
      wantsCop: map['wantsCop'] ?? false,
      state: RobberState.fromString(map['state'] ?? 'free'),
      jailedAt: (map['jailedAt'] as Timestamp?)?.toDate(),
      releasedAt: (map['releasedAt'] as Timestamp?)?.toDate(),
      rescueDisabledUntil: (map['rescueDisabledUntil'] as Timestamp?)?.toDate(),
      score: map['score'] ?? 0,
      stats: ParticipantStats.fromMap(map['stats'] ?? {}),
    );
  }
}

class ParticipantStats {
  final int catches;
  final int rescues;
  final int survivalSec;
  final bool keyUsed;

  ParticipantStats({
    this.catches = 0,
    this.rescues = 0,
    this.survivalSec = 0,
    this.keyUsed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'catches': catches,
      'rescues': rescues,
      'survivalSec': survivalSec,
      'keyUsed': keyUsed,
    };
  }

  factory ParticipantStats.fromMap(Map<String, dynamic> map) {
    return ParticipantStats(
      catches: map['catches'] ?? 0,
      rescues: map['rescues'] ?? 0,
      survivalSec: map['survivalSec'] ?? 0,
      keyUsed: map['keyUsed'] ?? false,
    );
  }
}
