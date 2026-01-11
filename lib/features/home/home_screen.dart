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

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isKicked && mounted) {
        _showKickedDialog(context);
      }
    });
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
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: HudText(
          'CATCH RUN',
          fontSize: 22,
          letterSpacing: 4,
          color: Colors.cyanAccent.withValues(alpha: 0.8),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showLogoutDialog(context, ref),
            icon: Icon(
              Icons.logout_rounded,
              color: Colors.cyanAccent.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final backgroundImage = orientation == Orientation.portrait
              ? 'assets/image/profile_setting_portrait.png'
              : 'assets/image/profile_setting_landscape.png';

          return SizedBox.expand(
            child: Stack(
              children: [
                // 1. Background Image
                Positioned.fill(
                  child: Image.asset(
                    backgroundImage,
                    fit: BoxFit.cover,
                  ),
                ),
                // 2. Dark Overlay & Gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // 3. Content
                userAsync.when(
                  data: (user) => SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
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
                ),
              ],
            ),
          );
        },
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
          onPressed: () => Navigator.pop(context),
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
            ref.read(authControllerProvider.notifier).signOut();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
