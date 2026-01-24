import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:catchrun/core/widgets/gradient_border.dart';

/// Custom HUD TextField with Neon Border for Onboarding
class OnboardingTextField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onRandomRequested;
  final bool useBlur;

  const OnboardingTextField({
    super.key,
    required this.controller,
    required this.onRandomRequested,
    this.useBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: useBlur ? 0.4 : 0.6),
        borderRadius: BorderRadius.circular(12),
        border: const GradientBorder(
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
    );

    if (!useBlur) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: content,
      ),
    );
  }
}
