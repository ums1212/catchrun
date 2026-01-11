import 'package:flutter/material.dart';
import 'package:catchrun/core/widgets/hud_text.dart';

/// Neon Style Icon Button
class NeonIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const NeonIconButton({
    super.key,
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
            HudText(
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
