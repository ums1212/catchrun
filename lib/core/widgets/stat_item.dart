import 'package:flutter/material.dart';
import 'package:catchrun/core/widgets/hud_text.dart';

class StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const StatItem({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = Colors.cyanAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HudText(
          label,
          fontSize: 10,
          color: Colors.white70,
          fontWeight: FontWeight.normal,
        ),
        const SizedBox(height: 4),
        HudText(
          value,
          fontSize: 18,
          color: valueColor,
        ),
      ],
    );
  }
}
