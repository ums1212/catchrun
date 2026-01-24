import 'dart:ui';
import 'package:flutter/material.dart';

/// Glassmorphism Avatar with Neon Ring
class GlassAvatar extends StatelessWidget {
  final String seed;
  final bool useBlur;

  const GlassAvatar({
    super.key, 
    required this.seed,
    this.useBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarContent = Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: useBlur ? 0.1 : 0.2),
        border: Border.all(
          color: Colors.white.withValues(alpha: useBlur ? 0.2 : 0.3),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Image.asset(
        'assets/image/profile$seed.png',
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Text(
            '👤',
            style: TextStyle(fontSize: 48),
          );
        },
      ),
    );

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
        if (!useBlur) 
          ClipRRect(
            borderRadius: BorderRadius.circular(70),
            child: avatarContent,
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(70),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: avatarContent,
            ),
          ),
      ],
    );
  }
}
