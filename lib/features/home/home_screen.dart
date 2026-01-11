import 'dart:ui';
import 'package:catchrun/core/widgets/hud_text.dart';
import 'package:catchrun/core/widgets/scifi_button.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'KickedDismiss',
      pageBuilder: (context, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HudText('강퇴 알림', fontSize: 20, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    const HudText(
                      '방장의 권한으로 강퇴당하셨습니다.',
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: SciFiButton(
                        text: '확인',
                        height: 45,
                        fontSize: 14,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
                            _HomeScreenProfile(
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
                  error: (e, s) => Center(
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'LogoutDismiss',
      pageBuilder: (context, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HudText('로그아웃', fontSize: 20, color: Colors.cyanAccent),
                    const SizedBox(height: 16),
                    const HudText(
                      '정말 로그아웃 하시겠습니까?',
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: HudText(
                              '취소',
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SciFiButton(
                            text: '확인',
                            height: 45,
                            fontSize: 14,
                            onPressed: () {
                              ref.read(authControllerProvider.notifier).signOut();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeScreenProfile extends StatelessWidget {
  final String nickname;
  final String? avatarSeed;

  const _HomeScreenProfile({
    required this.nickname,
    this.avatarSeed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer Glow Ring
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Glass Panel Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('👤', style: TextStyle(fontSize: 40)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.cyanAccent.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: HudText(
            '안녕하세요, $nickname님!',
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}