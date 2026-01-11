import 'package:flutter/material.dart';

/// Floating Animation Wrapper
class FloatingWidget extends StatelessWidget {
  final Widget child;

  const FloatingWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final offset = 10 * (1.0 - (2.0 * value - 1.0).abs());
        return AnimatedContainer(
          duration: const Duration(milliseconds: 2000),
          transform: Matrix4.translationValues(0, offset, 0),
          child: child,
        );
      },
      onEnd: () {},
      child: child,
    );
  }
}
