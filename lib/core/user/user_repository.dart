import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:catchrun/core/models/user_model.dart';
import 'package:catchrun/core/network/connectivity_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(
    FirebaseFirestore.instance,
    ref.watch(connectivityServiceProvider),
  );
});

class UserRepository {
  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivityService;

  UserRepository(this._firestore, this._connectivityService);

  CollectionReference<Map<String, dynamic>> get _usersConfig => _firestore.collection('users');

  Future<void> createUser(AppUser user) async {
    await _connectivityService.ensureConnection();
    await _usersConfig.doc(user.uid).set(user.toMap());
  }

  Future<AppUser?> getUser(String uid) async {
    await _connectivityService.ensureConnection();
    final doc = await _usersConfig.doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateUser(AppUser user) async {
    await _connectivityService.ensureConnection();
    await _usersConfig.doc(user.uid).update(user.toMap());
  }

  Future<bool> userExists(String uid) async {
    await _connectivityService.ensureConnection();
    final doc = await _usersConfig.doc(uid).get();
    return doc.exists;
  }

  Stream<AppUser?> watchUser(String uid) {
    return _usersConfig.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// 익명 계정 데이터를 삭제하는 용도로 사용
  Future<void> deleteAnonymousUser(String uid) async {
    await _connectivityService.ensureConnection();
    await _usersConfig.doc(uid).delete();
  }
}
