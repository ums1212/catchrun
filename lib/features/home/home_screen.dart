import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                child: const Icon(Icons.person, size: 40),
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              ),
              const SizedBox(height: 16),
              Text(
                '안녕하세요, ${user?.nickname ?? '사용자'}님!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              const Text('게임을 시작하거나 대기방에 입장하세요'),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('에러 발생: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Sprint 2에서 구현
        },
        label: const Text('게임 만들기'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
