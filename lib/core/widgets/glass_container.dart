import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final Color? color;
  final bool useBlur;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = 16,
    this.color,
    this.useBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        // 블러를 쓰지 않을 때는 조금 더 짙은 배경색을 사용하여 가독성 확보
        color: color ?? (useBlur 
            ? Colors.white.withValues(alpha: 0.05) 
            : Colors.white.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          // 테두리를 조금 더 선명하게 하여 유리 느낌 강조
          color: Colors.white.withValues(alpha: useBlur ? 0.1 : 0.2),
          width: 1.5,
        ),
        // 블러가 없을 때 깊이감을 주기 위해 아주 미세한 그림자 추가 고려 가능
      ),
      child: child,
    );

    if (!useBlur) return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: content,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: content,
      ),
    );
  }
}
