import 'dart:math';
import 'package:catchrun/core/providers/app_bar_provider.dart';
import 'package:catchrun/core/user/nickname_generator.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catchrun/core/widgets/hud_text.dart';
import 'package:catchrun/core/widgets/hud_section_header.dart';
import 'package:catchrun/core/widgets/scifi_button.dart';
import 'package:catchrun/features/onboarding/widgets/floating_widget.dart';
import 'package:catchrun/features/onboarding/widgets/glass_avatar.dart';
import 'package:catchrun/features/onboarding/widgets/neon_icon_button.dart';
import 'package:catchrun/features/onboarding/widgets/onboarding_text_field.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final bool isEditMode;
  final String? initialNickname;
  final String? initialAvatarSeed;

  const OnboardingScreen({
    super.key,
    this.isEditMode = false,
    this.initialNickname,
    this.initialAvatarSeed,
  });

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late TextEditingController _nicknameController;
  late String _avatarSeed;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      // 수정 모드: 기존 값으로 초기화
      _nicknameController = TextEditingController(text: widget.initialNickname ?? '');
      _avatarSeed = widget.initialAvatarSeed ?? '1';
      
      // Main Shell의 AppBar 설정
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(appBarProvider.notifier).state = AppBarConfig(
            title: '프로필 수정',
            centerTitle: true,
          );
        }
      });
    } else {
      // 신규 사용자: 랜덤 생성
      _nicknameController = TextEditingController(text: NicknameGenerator.generate());
      _avatarSeed = '1';
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _regenerateNickname() {
    setState(() {
      _nicknameController.text = NicknameGenerator.generate();
    });
  }

  void _regenerateAvatar() {
    setState(() {
      final oldSeed = int.tryParse(_avatarSeed) ?? 1;
      int newSeed;
      do {
        newSeed = Random().nextInt(4) + 1;
      } while (newSeed == oldSeed);
      _avatarSeed = newSeed.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          // 수정 모드에서 완료 시 홈으로 돌아가기
          if (widget.isEditMode && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text('시스템 오류: $error', style: const TextStyle(color: Colors.white)),
            ),
          );
        },
      );
    });

    final authState = ref.watch(authControllerProvider);

    return PopScope(
      canPop: widget.isEditMode, // 수정 모드에서는 바로 뒤로가기 가능
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (widget.isEditMode) return; // 수정 모드에서는 다이얼로그 없이 뒤로가기

        // 신규 사용자 모드에서만 취소 확인 다이얼로그 표시
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.cyanAccent, width: 1),
            ),
            title: const HudText(
              '프로필 설정 취소',
              fontSize: 18,
              color: Colors.white,
            ),
            content: const Text(
              '프로필 설정을 취소하고 로그인 화면으로 돌아가시겠습니까?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('아니오', style: TextStyle(color: Colors.cyanAccent)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('네', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );

        if (shouldPop == true && context.mounted) {
          ref.read(authControllerProvider.notifier).cancelRegistration();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: widget.isEditMode ? Colors.transparent : Colors.black,
        appBar: widget.isEditMode
            ? null // 수정 모드에서는 Main Shell의 AppBar 사용
            : AppBar(
                title: HudText(
                  '프로필 설정',
                  fontSize: 20,
                  letterSpacing: 2,
                  color: Colors.cyanAccent.withValues(alpha: 0.8),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.cyanAccent),
              ),
        body: OrientationBuilder(
          builder: (context, orientation) {
            final backgroundImage = orientation == Orientation.portrait
                ? 'assets/image/profile_setting_portrait.png'
                : 'assets/image/profile_setting_landscape.png';

            return SizedBox.expand(
              child: Stack(
                children: [
                  // 1. Background Image (신규 온보딩에서만 표시)
                  if (!widget.isEditMode)
                    Positioned.fill(
                      child: Image.asset(
                        backgroundImage,
                        fit: BoxFit.cover,
                      ),
                    ),
                  // 2. Scanline/CRT Effect Overlay (신규 온보딩에서만 표시)
                  if (!widget.isEditMode)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.9),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  // 3. Content
                  SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          // Avatar Area with Floating Effect
                          FloatingWidget(
                            child: Column(
                              children: [
                                GlassAvatar(seed: _avatarSeed),
                                const SizedBox(height: 16),
                                NeonIconButton(
                                  icon: Icons.refresh_rounded,
                                  label: '아바타 랜덤 생성',
                                  onPressed: _regenerateAvatar,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 60),
                          // Nickname Input Area
                          HudSectionHeader(title: '닉네임'),
                          const SizedBox(height: 16),
                          OnboardingTextField(
                            controller: _nicknameController,
                            onRandomRequested: _regenerateNickname,
                          ),
                          const SizedBox(height: 80),
                          // Action Button
                          if (authState.isLoading)
                            const CircularProgressIndicator(color: Colors.cyanAccent)
                          else
                            SciFiButton(
                              text: widget.isEditMode ? '수정 완료' : '설정 완료',
                              onPressed: () {
                                final nickname = _nicknameController.text.trim();
                                if (nickname.isNotEmpty) {
                                  ref.read(authControllerProvider.notifier).completeProfile(
                                        nickname,
                                        _avatarSeed,
                                      );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('코드네임을 입력해 주세요')),
                                  );
                                }
                              },
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
