import 'package:cloud_firestore/cloud_firestore.dart';

enum GameStatus {
  lobby,
  playing,
  finished;

  static GameStatus fromString(String value) {
    return GameStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GameStatus.lobby,
    );
  }
}

class GameModel {
  final String id;
  final String title;
  final String hostUid;
  final String gameCode;
  final String inviteCode;
  final String joinQrToken;
  final bool joinQrEnabled;
  final GameStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final int durationSec;
  final GameRule rule;
  final GameCounts counts;

  GameModel({
    required this.id,
    required this.title,
    required this.hostUid,
    required this.gameCode,
    required this.inviteCode,
    required this.joinQrToken,
    this.joinQrEnabled = true,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.endsAt,
    this.durationSec = 600,
    required this.rule,
    required this.counts,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'hostUid': hostUid,
      'gameCode': gameCode,
      'inviteCode': inviteCode,
      'joinQrToken': joinQrToken,
      'joinQrEnabled': joinQrEnabled,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'endsAt': endsAt != null ? Timestamp.fromDate(endsAt!) : null,
      'durationSec': durationSec,
      'rule': rule.toMap(),
      'counts': counts.toMap(),
    };
  }

  factory GameModel.fromMap(Map<String, dynamic> map, String id) {
    return GameModel(
      id: id,
      title: map['title'] ?? '',
      hostUid: map['hostUid'] ?? '',
      gameCode: map['gameCode'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      joinQrToken: map['joinQrToken'] ?? '',
      joinQrEnabled: map['joinQrEnabled'] ?? true,
      status: GameStatus.fromString(map['status'] ?? 'lobby'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (map['startedAt'] as Timestamp?)?.toDate(),
      endsAt: (map['endsAt'] as Timestamp?)?.toDate(),
      durationSec: map['durationSec'] ?? 600,
      rule: GameRule.fromMap(map['rule'] ?? {}),
      counts: GameCounts.fromMap(map['counts'] ?? {}),
    );
  }
}

class GameRule {
  final bool useQr;
  final bool useNfc;
  final int copsCount;
  final int robbersCount;
  final bool autoAssignRoles;

  GameRule({
    this.useQr = true,
    this.useNfc = true,
    this.copsCount = 2,
    this.robbersCount = 6,
    this.autoAssignRoles = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'useQr': useQr,
      'useNfc': useNfc,
      'copsCount': copsCount,
      'robbersCount': robbersCount,
      'autoAssignRoles': autoAssignRoles,
    };
  }

  factory GameRule.fromMap(Map<String, dynamic> map) {
    return GameRule(
      useQr: map['useQr'] ?? true,
      useNfc: map['useNfc'] ?? true,
      copsCount: map['copsCount'] ?? 2,
      robbersCount: map['robbersCount'] ?? 6,
      autoAssignRoles: map['autoAssignRoles'] ?? true,
    );
  }
}

class GameCounts {
  final int total;
  final int cops;
  final int robbers;
  final int robbersFree;
  final int robbersJailed;

  GameCounts({
    this.total = 0,
    this.cops = 0,
    this.robbers = 0,
    this.robbersFree = 0,
    this.robbersJailed = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'total': total,
      'cops': cops,
      'robbers': robbers,
      'robbersFree': robbersFree,
      'robbersJailed': robbersJailed,
    };
  }

  factory GameCounts.fromMap(Map<String, dynamic> map) {
    return GameCounts(
      total: map['total'] ?? 0,
      cops: map['cops'] ?? 0,
      robbers: map['robbers'] ?? 0,
      robbersFree: map['robbersFree'] ?? 0,
      robbersJailed: map['robbersJailed'] ?? 0,
    );
  }
}
