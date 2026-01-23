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
      GoRoute(
        path: '/join',
        redirect: (context, state) {
          final gameId = state.uri.queryParameters['gameId'];
          final nfcKeyId = state.uri.queryParameters['nfcKeyId'];
          if (gameId != null) {
            // nfcKeyId가 있는 경우 참여 로직을 수행하도록 로비 화면으로 전달하거나
            // 별도의 처리 후 로비로 이동하게 할 수 있습니다.
            // 여기서는 일단 로비로 이동시키고 로비에서 nfcKeyId가 있다면 
            // 자동으로 참여 처리를 시도하는 방식을 고려하거나,
            // 단순히 로비 화면으로 진입시키도록 합니다.
            return '/lobby/$gameId${nfcKeyId != null ? '?nfcKeyId=$nfcKeyId' : ''}';
          }
          return '/home';
        },
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
          GoRoute(
            path: '/edit-profile',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return CustomTransitionPage(
                key: state.pageKey,
                child: OnboardingScreen(
                  isEditMode: true,
                  initialNickname: extra['nickname'],
                  initialAvatarSeed: extra['avatarSeed'],
                ),
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

      final isRoot = state.matchedLocation == '/';

      // 1. 초기 로딩 상태 (Auth 상태를 아직 확인할 수 없는 경우)
      if (authState.isLoading || userProfile.isLoading) {
        // 루트 경로에서 시작한 경우에만 스플래시로 이동시켜 초기화를 기다립니다.
        // 딥링크 등으로 구체적인 경로가 있는 경우는 그 의도를 유지하기 위해 리다이렉트하지 않습니다.
        return (isRoot && !splashing) ? '/splash' : null;
      }

      final user = authState.value;
      final profile = userProfile.value;

      // 2. 미인증 상태
      if (user == null) {
        // 이미 로그인 화면이면 그대로 둠, 아니면 로그인으로
        return loggingIn ? null : '/login';
      }

      // 3. 인증은 되었으나 프로필이 미완성인 상태
      if (profile == null || !profile.isProfileComplete) {
        // 이미 온보딩 화면이면 그대로 둠, 아니면 온보딩으로
        return onboarding ? null : '/onboarding';
      }

      // 4. 모든 설정 완료 상태
      // 현재 위치가 게이트 화면(root, splash, login, onboarding)인 경우에만 홈으로 보냅니다.
      // 그 외의 구체적인 위치(로비, 게임 화면 등)는 기존 의도를 존중하여 그대로 유지합니다.
      if (loggingIn || onboarding || splashing || isRoot) {
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
