import 'package:flutter/material.dart';
import 'hud_text.dart';

class HudSectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const HudSectionHeader({
    super.key,
    required this.title,
    this.color = Colors.cyanAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        HudText(
          title,
          fontSize: 12,
          color: color.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.4),
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
