import 'package:flutter/material.dart';

class HudText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final double letterSpacing;
  final FontWeight fontWeight;
  final TextAlign? textAlign;

  const HudText(
    this.text, {
    super.key,
    this.fontSize = 14,
    this.color = Colors.white,
    this.letterSpacing = 1.0,
    this.fontWeight = FontWeight.bold,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
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
