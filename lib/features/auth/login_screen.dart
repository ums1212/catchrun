import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Catch Run에 오신 것을 환영합니다'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/onboarding'),
              child: const Text('구글 로그인 (임시)'),
            ),
          ],
        ),
      ),
    );
  }
}
