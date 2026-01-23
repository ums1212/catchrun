import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:catchrun/core/widgets/hud_text.dart';

class HomeProfileCard extends StatelessWidget {
  final String nickname;
  final String? avatarSeed;
  final VoidCallback? onTap;

  const HomeProfileCard({
    super.key,
    required this.nickname,
    this.avatarSeed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
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
                    child: Image.asset(
                      'assets/image/profile${avatarSeed ?? '1'}.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text('👤', style: TextStyle(fontSize: 40));
                      },
                    ),
                  ),
                ),
              ),
              // Edit indicator
              if (onTap != null)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
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
