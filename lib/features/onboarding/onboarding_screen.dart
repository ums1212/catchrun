import 'dart:ui';
import 'package:catchrun/core/user/nickname_generator.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late TextEditingController _nicknameController;
  late String _avatarSeed;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: NicknameGenerator.generate());
    _avatarSeed = const Uuid().v4();
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
      _avatarSeed = const Uuid().v4();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: _HudText(
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
                // 1. Background Image
                Positioned.fill(
                  child: Image.asset(
                    backgroundImage,
                    fit: BoxFit.cover,
                  ),
                ),
                // 2. Scanline/CRT Effect Overlay (Optional but cool)
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
                        _FloatingWidget(
                          child: Column(
                            children: [
                              _GlassAvatar(seed: _avatarSeed),
                              const SizedBox(height: 16),
                              _NeonIconButton(
                                icon: Icons.refresh_rounded,
                                label: '아바타 랜덤 생성',
                                onPressed: _regenerateAvatar,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 60),
                        // Nickname Input Area
                        _HudSectionHeader(title: '닉네임'),
                        const SizedBox(height: 16),
                        _HudTextField(
                          controller: _nicknameController,
                          onRandomRequested: _regenerateNickname,
                        ),
                        const SizedBox(height: 80),
                        // Action Button
                        if (authState.isLoading)
                          const CircularProgressIndicator(color: Colors.cyanAccent)
                        else
                          _SciFiButton(
                            text: '미션 시작',
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
    );
  }
}

/// HUD Text with slight glow
class _HudText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final double letterSpacing;
  final FontWeight fontWeight;

  const _HudText(
    this.text, {
    this.fontSize = 14,
    this.color = Colors.white,
    this.letterSpacing = 1.0,
    this.fontWeight = FontWeight.bold,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        shadows: [
          Shadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

/// Section Header for HUD
class _HudSectionHeader extends StatelessWidget {
  final String title;

  const _HudSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.cyanAccent,
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.6),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _HudText(
          title,
          fontSize: 12,
          color: Colors.cyanAccent.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyanAccent.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Floating Animation Wrapper
class _FloatingWidget extends StatelessWidget {
  final Widget child;

  const _FloatingWidget({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final offset = 10 * (1.0 - (2.0 * value - 1.0).abs()); // Simple bounce approximation
        // Using a better sine based floating
        return AnimatedContainer(
          duration: const Duration(milliseconds: 2000),
          transform: Matrix4.translationValues(0, offset, 0),
          child: child,
        );
      },
      onEnd: () {
        // Not ideal for continuous loop without a proper controller, 
        // but for a quick HUD feel we can use a repeating AnimationController or a custom wrapper.
      },
      child: child, // Optimized loop in a real app would use a StatefulWidget with Ticker
    );
  }
}

/// Glassmorphism Avatar with Neon Ring
class _GlassAvatar extends StatelessWidget {
  final String seed;

  const _GlassAvatar({required this.seed});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Glow Ring
        Container(
          width: 140,
          height: 140,
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
        // Glass Panel
        ClipRRect(
          borderRadius: BorderRadius.circular(70),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '👤', // Replacing with actual DiceBear later
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Neon Style Icon Button
class _NeonIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _NeonIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.cyanAccent),
            const SizedBox(width: 8),
            _HudText(
              label,
              fontSize: 10,
              color: Colors.cyanAccent,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom HUD TextField with Neon Border
class _HudTextField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onRandomRequested;

  const _HudTextField({
    required this.controller,
    required this.onRandomRequested,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: const _GradientBorder(
              width: 1.5,
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.redAccent],
              ),
            ),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, letterSpacing: 1.2),
            maxLength: 15,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: InputBorder.none,
              counterStyle: const TextStyle(color: Colors.white54, fontSize: 10),
              suffixIcon: IconButton(
                icon: const Icon(Icons.casino_outlined, color: Colors.cyanAccent),
                onPressed: onRandomRequested,
                tooltip: '랜덤 생성',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sci-Fi Style Action Button
class _SciFiButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _SciFiButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Colors.redAccent],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(-5, 0),
            ),
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(5, 0),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Inner Shine
            Positioned(
              top: 2,
              left: 10,
              right: 10,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            _HudText(
              text,
              fontSize: 18,
              letterSpacing: 3,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple Gradient Border Painter
class _GradientBorder extends BoxBorder {
  final Gradient gradient;
  final double width;

  const _GradientBorder({required this.gradient, this.width = 1.0});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  bool get isUniform => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final Paint paint = Paint()
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..shader = gradient.createShader(rect);

    if (borderRadius != null) {
      canvas.drawRRect(borderRadius.toRRect(rect).deflate(width / 2), paint);
    } else {
      canvas.drawRect(rect.deflate(width / 2), paint);
    }
  }

  @override
  ShapeBorder scale(double t) => _GradientBorder(gradient: gradient, width: width * t);

  @override
  BorderSide get bottom => BorderSide.none;
  @override
  BorderSide get top => BorderSide.none;
}
