import 'dart:ui';
import 'package:flutter/material.dart';
import 'hud_text.dart';
import 'gradient_border.dart';

class HudTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;

  const HudTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HudText(labelText, fontSize: 12, color: Colors.white70),
        const SizedBox(height: 8),
        ClipRRect(
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
              child: TextFormField(
                controller: controller,
                style: const TextStyle(color: Colors.white, letterSpacing: 1.2),
                validator: validator,
                keyboardType: keyboardType,
                obscureText: obscureText,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  border: InputBorder.none,
                  hintText: hintText,
                  hintStyle: const TextStyle(color: Colors.white24),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
