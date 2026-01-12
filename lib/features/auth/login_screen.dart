import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:catchrun/features/auth/widgets/auth_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 에러 발생 시 SnackBar 표시
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('로그인 실패: $error')),
          );
        },
      );
    });

    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (rect) {
                      return const RadialGradient(
                        center: Alignment.center,
                        radius: 1.5,
                        colors: [Colors.black, Colors.transparent],
                        stops: [0.8, 1.0],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Image.asset(
                      'assets/image/title_logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 64),
                  if (authState.isLoading)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    Column(
                      children: [
                        InkWell(
                          onTap: () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/image/android_neutral_sq_ctn@4x.png',
                            height: 56,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => ref.read(authControllerProvider.notifier).signInAnonymously(),
                          child: const Text(
                            '게스트로 시작하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
