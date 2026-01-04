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
      print('DEBUG: Starting Google Sign In...');
      final credential = await _authRepository.signInWithGoogle();
      
      if (credential != null && credential.user != null) {
        print('DEBUG: Google Sign In Success, uid: ${credential.user!.uid}');
        // 기존 사용자인지 확인
        final exists = await _userRepository.userExists(credential.user!.uid);
        print('DEBUG: User exists in Firestore: $exists');
        
        if (!exists) {
          print('DEBUG: Creating new user in Firestore...');
          final newUser = AppUser(
            uid: credential.user!.uid,
            email: credential.user!.email ?? '',
          );
          await _userRepository.createUser(newUser);
          print('DEBUG: New user created');
        }
      } else {
        print('DEBUG: Google Sign In cancelled or failed (credential is null)');
      }
    });
    
    if (state.hasError) {
      print('DEBUG: Sign In Error: ${state.error}');
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _authRepository.signOut());
  }

  Future<void> completeProfile(String nickname, String avatarSeed) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      print('DEBUG: Profile completion failed - No current user');
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      print('DEBUG: Completing profile for uid: ${currentUser.uid}, nickname: $nickname');
      final user = await _userRepository.getUser(currentUser.uid);
      if (user != null) {
        final updatedUser = user.copyWith(
          nickname: nickname,
          avatarSeed: avatarSeed,
        );
        await _userRepository.updateUser(updatedUser);
        print('DEBUG: Profile updated in Firestore');
      } else {
        print('DEBUG: Profile completion failed - User document not found in Firestore');
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }
    });

    if (state.hasError) {
      print('DEBUG: Profile completion error: ${state.error}');
    }
  }
}
