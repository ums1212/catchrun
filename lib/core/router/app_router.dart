import 'package:catchrun/core/auth/auth_repository.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:catchrun/features/auth/login_screen.dart';
import 'package:catchrun/features/home/home_screen.dart';
import 'package:catchrun/features/onboarding/onboarding_screen.dart';
import 'package:catchrun/features/splash/splash_screen.dart';
import 'package:catchrun/features/game/presentation/create_game_screen.dart';
import 'package:catchrun/features/game/presentation/join_game_screen.dart';
import 'package:catchrun/features/game/presentation/lobby_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/create-game',
        builder: (context, state) => const CreateGameScreen(),
      ),
      GoRoute(
        path: '/join-game',
        builder: (context, state) => const JoinGameScreen(),
      ),
      GoRoute(
        path: '/lobby/:gameId',
        builder: (context, state) {
          final gameId = state.pathParameters['gameId']!;
          return LobbyScreen(gameId: gameId);
        },
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      final userProfile = ref.read(userProvider);

      final loggingIn = state.matchedLocation == '/login';
      final onboarding = state.matchedLocation == '/onboarding';
      final splashing = state.matchedLocation == '/splash';

      // 1. 초기 로딩 상태 (Auth 상태를 아직 확인할 수 없는 경우)
      // watch 대신 read를 쓰되, redirect가 호출될 때는 이미 상태가 어느 정도 안정된 후임.
      if (authState.isLoading || userProfile.isLoading) {
        return splashing ? null : '/splash';
      }

      final user = authState.value;
      final profile = userProfile.value;

      // 2. 미인증 상태
      if (user == null) {
        return loggingIn ? null : '/login';
      }

      // 3. 인증은 되었으나 프로필이 미완성인 상태
      if (profile == null || !profile.isProfileComplete) {
        return onboarding ? null : '/onboarding';
      }

      // 4. 모든 설정 완료 상태
      if (loggingIn || onboarding || splashing) {
        return '/home';
      }

      return null;
    },
    // 리다이렉션이 상태 변화에 따라 트리거되도록 Listenable 추가
    refreshListenable: Listenable.merge([
      _ValueNotifierFromProvider(ref, authStateChangesProvider),
      _ValueNotifierFromProvider(ref, userProvider),
    ]),
  );
});

// StreamProvider/FutureProvider를 Listenable로 변환해주는 helper 클래스
class _ValueNotifierFromProvider extends ChangeNotifier {
  final Ref ref;
  _ValueNotifierFromProvider(this.ref, ProviderBase provider) {
    ref.listen(provider, (_, __) => notifyListeners());
  }
}
