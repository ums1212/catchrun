import 'package:flutter/material.dart';
import 'package:catchrun/core/widgets/hud_text.dart';

class CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const CounterButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: onPressed != null ? color.withValues(alpha: 0.5) : Colors.white12,
            width: 1.5,
          ),
          color: onPressed != null ? color.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 20,
          color: onPressed != null ? color : Colors.white12,
        ),
      ),
    );
  }
}

class ParticipantCounter extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onCountPressed;

  const ParticipantCounter({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    required this.onIncrement,
    this.onDecrement,
    this.onCountPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        HudText(
          label,
          fontSize: 10,
          color: Colors.white.withValues(alpha: 0.5),
          fontWeight: FontWeight.normal,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CounterButton(
              icon: Icons.remove_rounded,
              onPressed: onDecrement,
              color: color,
            ),
            Expanded(
              child: GestureDetector(
                onTap: onCountPressed,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: HudText(
                    '$count',
                    fontSize: 24,
                    color: color,
                  ),
                ),
              ),
            ),
            CounterButton(
              icon: Icons.add_rounded,
              onPressed: onIncrement,
              color: color,
            ),
          ],
        ),
      ],
    );
  }
}
