import 'package:catchrun/core/models/game_model.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateGameScreen extends ConsumerStatefulWidget {
  const CreateGameScreen({super.key});

  @override
  ConsumerState<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends ConsumerState<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  int _durationMinutes = 10;
  int _copsCount = 2;
  int _robbersCount = 6;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _createGame() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(userProvider).value;
      if (user == null) throw Exception('사용자 정보를 찾을 수 없습니다.');

      final gameId = await ref.read(gameRepositoryProvider).createGame(
            title: _titleController.text,
            rule: GameRule(
              copsCount: _copsCount,
              robbersCount: _robbersCount,
              useQr: true,
              useNfc: true,
              autoAssignRoles: true,
            ),
            host: user,
          );

      if (mounted) {
        context.pushReplacement('/lobby/$gameId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게임 생성 중 오류 발생: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게임 만들기')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: '게임 이름',
                    hintText: '우리동네 한판!',
                    hintStyle: TextStyle(color: Theme.of(context).hintColor.withOpacity(0.4)),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => 
                      (value == null || value.isEmpty) ? '게임 이름을 입력해주세요.' : null,
                ),
                const SizedBox(height: 24),
                Text(
                  '제한 시간: $_durationMinutes분',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Slider(
                  value: _durationMinutes.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  label: '$_durationMinutes분',
                  onChanged: (val) => setState(() => _durationMinutes = val.toInt()),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('경찰 인원'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: _copsCount > 1 
                                    ? () => setState(() => _copsCount--) 
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('$_copsCount명', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              IconButton(
                                onPressed: () => setState(() => _copsCount++),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('도둑 인원'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: _robbersCount > 1 
                                    ? () => setState(() => _robbersCount--) 
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('$_robbersCount명', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              IconButton(
                                onPressed: () => setState(() => _robbersCount++),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _createGame,
                  icon: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.rocket_launch),
                  label: const Text('게임 생성 및 대기방 입장'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
