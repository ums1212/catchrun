import 'package:catchrun/core/user/nickname_generator.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late TextEditingController _nicknameController;
  late String _avatarSeed;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: NicknameGenerator.generate());
    _avatarSeed = const Uuid().v4();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _regenerateNickname() {
    setState(() {
      _nicknameController.text = NicknameGenerator.generate();
    });
  }

  void _regenerateAvatar() {
    setState(() {
      _avatarSeed = const Uuid().v4();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 에러 발생 시 SnackBar 표시
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('프로필 설정 실패: $error')),
          );
        },
      );
    });

    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('프로필 설정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar Preview Placeholder
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                'Avatar', // 나중에 실제 아바타 위젯(예: DiceBear API)으로 교체
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
            TextButton.icon(
              onPressed: _regenerateAvatar,
              icon: const Icon(Icons.refresh),
              label: const Text('아바타 변경'),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                labelText: '닉네임',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.casino),
                  onPressed: _regenerateNickname,
                  tooltip: '랜덤 닉네임 생성',
                ),
              ),
              maxLength: 15,
            ),
            const SizedBox(height: 40),
            if (authState.isLoading)
              const CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final nickname = _nicknameController.text.trim();
                    if (nickname.isNotEmpty) {
                      ref.read(authControllerProvider.notifier).completeProfile(
                            nickname,
                            _avatarSeed,
                          );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('닉네임을 입력해 주세요')),
                      );
                    }
                  },
                  child: const Text('시작하기'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
