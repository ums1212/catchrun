import 'dart:ui';
import 'package:flutter/material.dart';
import 'gradient_border.dart';
import 'hud_text.dart';

class SciFiButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isOutlined;
  final double height;
  final double fontSize;
  final Color? color;

  const SciFiButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isOutlined = false,
    this.height = 60,
    this.fontSize = 18,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Colors.blueAccent;
    final secondaryColor = Colors.redAccent;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isOutlined
              ? null
              : LinearGradient(
                  colors: [themeColor, secondaryColor],
                ),
          color: isOutlined ? Colors.black.withValues(alpha: 0.4) : null,
          border: isOutlined
              ? GradientBorder(
                  width: 1.5,
                  gradient: LinearGradient(
                    colors: [themeColor, secondaryColor],
                  ),
                )
              : null,
          boxShadow: isOutlined
              ? []
              : [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(-5, 0),
                  ),
                  BoxShadow(
                    color: secondaryColor.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(5, 0),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!isOutlined)
                  Positioned(
                    top: 2,
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.3),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: fontSize + 4),
                      const SizedBox(width: 12),
                    ],
                    HudText(
                      text,
                      fontSize: fontSize,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
