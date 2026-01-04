import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catch Run'),
        actions: [
          IconButton(
            onPressed: () {
              // 로그아웃 확인 다이얼로그
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('정말 로그아웃 하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(authControllerProvider.notifier).signOut();
                        Navigator.pop(context);
                      },
                      child: const Text('확인'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                child: const Icon(Icons.person, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                '안녕하세요, ${user?.nickname ?? '사용자'}님!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.push('/create-game'),
                      icon: const Icon(Icons.add),
                      label: const Text('게임 만들기'),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/join-game'),
                      icon: const Icon(Icons.group_add),
                      label: const Text('게임 참가하기'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('에러 발생: $e')),
      ),
    );
  }
}
