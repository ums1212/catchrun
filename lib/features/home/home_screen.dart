import 'package:catchrun/core/providers/app_bar_provider.dart';
import 'package:catchrun/core/router/app_router.dart';
import 'package:catchrun/core/widgets/hud_dialog.dart';
import 'package:catchrun/core/widgets/hud_text.dart';
import 'package:catchrun/core/widgets/scifi_button.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:catchrun/features/home/widgets/home_profile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final bool isKicked;
  const HomeScreen({super.key, this.isKicked = false});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with RouteAware {
  RouteObserver<ModalRoute<void>>? _routeObserver;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateAppBar();
      if (widget.isKicked) {
        _showKickedDialog(context);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RouteObserver 구독
    _routeObserver?.unsubscribe(this);
    _routeObserver = ref.read(mainShellRouteObserverProvider);
    _routeObserver?.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // 빌드 완료 후 앱바 업데이트 (Riverpod provider 수정은 빌드 중 불가)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateAppBar();
    });
  }

  void _updateAppBar() {
    ref.read(appBarProvider.notifier).state = AppBarConfig(
      title: 'CATCH RUN',
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () => _showLogoutDialog(context, ref),
          icon: Icon(
            Icons.logout_rounded,
            color: Colors.cyanAccent.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isKicked && !oldWidget.isKicked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showKickedDialog(context);
        }
      });
    }
  }

  void _showKickedDialog(BuildContext context) {
    HudDialog.show(
      context: context,
      title: '강퇴 알림',
      titleColor: Colors.redAccent,
      contentText: '방장의 권한으로 강퇴당하셨습니다.',
      actions: [
        SciFiButton(
          text: '확인',
          height: 45,
          fontSize: 14,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) => SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Area
                HomeProfileCard(
                  nickname: user?.nickname ?? '사용자',
                  avatarSeed: user?.avatarSeed,
                ),
                const SizedBox(height: 60),
                // Action Buttons
                SciFiButton(
                  text: '게임 만들기',
                  onPressed: () => context.push('/create-game'),
                  icon: Icons.add_rounded,
                ),
                const SizedBox(height: 24),
                SciFiButton(
                  text: '게임 참가하기',
                  onPressed: () => context.push('/join-game'),
                  icon: Icons.group_add_rounded,
                  isOutlined: true,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      ),
      error: (e, s) => const Center(
        child: HudText('데이터를 불러올 수 없습니다', color: Colors.redAccent),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    HudDialog.show(
      context: context,
      title: '로그아웃',
      contentText: '정말 로그아웃 하시겠습니까?',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: HudText(
            '취소',
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        SciFiButton(
          text: '확인',
          height: 45,
          fontSize: 14,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            ref.read(authControllerProvider.notifier).signOut();
          },
        ),
      ],
    );
  }
}
