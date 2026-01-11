import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:catchrun/core/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersConfig => _firestore.collection('users');

  Future<void> createUser(AppUser user) async {
    await _usersConfig.doc(user.uid).set(user.toMap());
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _usersConfig.doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateUser(AppUser user) async {
    await _usersConfig.doc(user.uid).update(user.toMap());
  }

  Future<bool> userExists(String uid) async {
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
}
