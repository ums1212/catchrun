import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:catchrun/core/widgets/gradient_border.dart';

/// Custom HUD TextField with Neon Border for Onboarding
class OnboardingTextField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onRandomRequested;

  const OnboardingTextField({
    super.key,
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
        ),
      ),
    );
  }
}
