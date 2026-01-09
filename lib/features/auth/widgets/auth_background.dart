import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 배경 이미지 (Orientation 감지)
        Positioned.fill(
          child: OrientationBuilder(
            builder: (context, orientation) {
              final imagePath = orientation == Orientation.portrait
                  ? 'assets/image/login_screen_portrait.png'
                  : 'assets/image/login_screen_landscape.png';
              return Image.asset(
                imagePath,
                fit: BoxFit.cover,
              );
            },
          ),
        ),
        // 배경 가독성을 위한 오버레이
        Container(
          color: Colors.black.withOpacity(0.4),
        ),
        // 실제 콘텐츠
        child,
      ],
    );
  }
}
