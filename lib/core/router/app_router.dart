import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:catchrun/core/auth/auth_repository.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:catchrun/features/auth/login_screen.dart';
import 'package:catchrun/features/home/home_screen.dart';
import 'package:catchrun/features/onboarding/onboarding_screen.dart';
import 'package:catchrun/features/splash/splash_screen.dart';
import 'package:catchrun/features/game/presentation/create_game_screen.dart';
import 'package:catchrun/features/game/presentation/join_game_screen.dart';
import 'package:catchrun/features/game/presentation/lobby_screen.dart';
import 'package:catchrun/features/game/presentation/play_screen.dart';
import 'package:catchrun/features/game/presentation/qr_scan_screen.dart';
import 'package:catchrun/features/game/presentation/prison_screen.dart';
import 'package:catchrun/features/game/presentation/result_screen.dart';
import 'package:catchrun/core/router/main_shell_wrapper.dart';
import 'package:catchrun/core/router/game_shell_wrapper.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _gameShellNavigatorKey = GlobalKey<NavigatorState>();

/// Main Shell용 RouteObserver (HomeScreen, CreateGameScreen, JoinGameScreen)
final mainShellRouteObserverProvider = Provider<RouteObserver<ModalRoute<void>>>((ref) {
  return RouteObserver<ModalRoute<void>>();
});

/// Game Shell용 RouteObserver (PlayScreen, PrisonScreen, QrScanScreen)
final gameShellRouteObserverProvider = Provider<RouteObserver<ModalRoute<void>>>((ref) {
  return RouteObserver<ModalRoute<void>>();
});

final routerProvider = Provider<GoRouter>((ref) {
  final mainShellObserver = ref.watch(mainShellRouteObserverProvider);
  final gameShellObserver = ref.watch(gameShellRouteObserverProvider);
  
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // 1. Independent Screens
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
      
      // 2. Main Shell (Home, Create, Join, Lobby)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        observers: [mainShellObserver],
        builder: (context, state, child) => MainShellWrapper(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) {
              final isKicked = state.uri.queryParameters['kicked'] == 'true';
              return CustomTransitionPage(
                key: state.pageKey,
                child: HomeScreen(isKicked: isKicked),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(position: Tween(begin: Offset(1, 0), end: Offset.zero).animate(animation), child: child);
                },
              );
            },
          ),
          GoRoute(
            path: '/create-game',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const CreateGameScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(position: Tween(begin: Offset(1, 0), end: Offset.zero).animate(animation), child: child);
              },
            ),
          ),
          GoRoute(
            path: '/join-game',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const JoinGameScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(position: Tween(begin: Offset(1, 0), end: Offset.zero).animate(animation), child: child);
              },
            ),
          ),
          GoRoute(
            path: '/lobby/:gameId',
            pageBuilder: (context, state) {
              final gameId = state.pathParameters['gameId']!;
              return CustomTransitionPage(
                key: state.pageKey,
                child: LobbyScreen(gameId: gameId),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(position: Tween(begin: Offset(1, 0), end: Offset.zero).animate(animation), child: child);
                },
              );
            },
          ),
        ],
      ),

      // 3. Game Shell (Play, QrScan, Prison)
      ShellRoute(
        navigatorKey: _gameShellNavigatorKey,
        observers: [gameShellObserver],
        builder: (context, state, child) => GameShellWrapper(child: child),
        routes: [
          GoRoute(
            path: '/play/:gameId',
            pageBuilder: (context, state) {
              final gameId = state.pathParameters['gameId']!;
              return CustomTransitionPage(
                key: state.pageKey,
                child: PlayScreen(gameId: gameId),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              );
            },
          ),
          GoRoute(
            path: '/qr-scan/:gameId',
            pageBuilder: (context, state) {
              final gameId = state.pathParameters['gameId']!;
              final isCop = state.uri.queryParameters['isCop'] == 'true';
              return CustomTransitionPage(
                key: state.pageKey,
                child: QrScanScreen(gameId: gameId, isCop: isCop),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              );
            },
          ),
          GoRoute(
            path: '/prison/:gameId',
            pageBuilder: (context, state) {
              final gameId = state.pathParameters['gameId']!;
              return CustomTransitionPage(
                key: state.pageKey,
                child: PrisonScreen(gameId: gameId),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              );
            },
          ),
        ],
      ),

      // 4. Result (독립적으로 두거나 Game Shell에 포함 가능, 여기서는 일단 독립)
      GoRoute(
        path: '/result/:gameId',
        builder: (context, state) {
          final gameId = state.pathParameters['gameId']!;
          return ResultScreen(gameId: gameId);
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
    refreshListenable: _GoRouterRefreshStream(ref),
  );
});

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Ref ref) {
    ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
    ref.listen(userProvider, (_, __) => notifyListeners());
  }
}
