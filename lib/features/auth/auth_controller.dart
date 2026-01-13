import 'package:catchrun/core/auth/auth_repository.dart';
import 'package:catchrun/core/models/user_model.dart';
import 'package:catchrun/core/user/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 현재 인증된 사용자의 Firestore 정보를 가져오는 프로바이더
final userProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateChangesProvider).value;
  if (authState == null) return Stream.value(null);

  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.watchUser(authState.uid);
});

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(userRepositoryProvider),
  );
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  AuthController(this._authRepository, this._userRepository) : super(const AsyncData(null));

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await _authRepository.signInWithGoogle();
      
      if (credential != null && credential.user != null) {
        await _handleUserSignIn(credential.user!);
      }
    });
  }

  Future<void> signInAnonymously() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await _authRepository.signInAnonymously();
      
      if (credential != null && credential.user != null) {
        await _handleUserSignIn(credential.user!);
      }
    });
  }

  Future<void> _handleUserSignIn(User firebaseUser) async {
    final exists = await _userRepository.userExists(firebaseUser.uid);

    if (!exists) {
      final newUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
      );
      await _userRepository.createUser(newUser);
    }
  }


  Future<void> signOut() async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (currentUser.isAnonymous) {
        // 익명 계정인 경우 계정 먼저 삭제 (리다이렉션이 /login으로 향하도록)
        final uid = currentUser.uid;
        await _authRepository.deleteAnonymousUser();
        await _userRepository.deleteAnonymousUser(uid);
      } else {
        // 일반 계정인 경우 로그아웃만 수행
        await _authRepository.signOut();
      }
    });
  }

  Future<void> completeProfile(String nickname, String avatarSeed) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      throw Exception('인증 세션이 만료되었습니다. 다시 로그인해주세요.');
    }


    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await _userRepository.getUser(currentUser.uid);
      if (user != null) {
        final updatedUser = user.copyWith(
          nickname: nickname,
          avatarSeed: avatarSeed,
        );
        await _userRepository.updateUser(updatedUser);
      } else {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }
    });
  }

  Future<void> cancelRegistration() async {
    await signOut();
  }
}
