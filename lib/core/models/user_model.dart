import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String? nickname;
  final String? avatarSeed;
  final String? activeGameId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.uid,
    required this.email,
    this.nickname,
    this.avatarSeed,
    this.activeGameId,
    this.createdAt,
    this.updatedAt,
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? nickname,
    String? avatarSeed,
    String? activeGameId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatarSeed: avatarSeed ?? this.avatarSeed,
      activeGameId: activeGameId ?? this.activeGameId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'avatarSeed': avatarSeed,
      'activeGameId': activeGameId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      uid: id,
      email: map['email'] ?? '',
      nickname: map['nickname'],
      avatarSeed: map['avatarSeed'],
      activeGameId: map['activeGameId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isProfileComplete => nickname != null && nickname!.isNotEmpty;
}
