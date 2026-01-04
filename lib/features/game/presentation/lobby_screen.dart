import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/game_model.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final String gameId;
  const LobbyScreen({super.key, required this.gameId});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  late final AppLifecycleListener _lifecycleListener;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onDetach: _leaveGameSilently,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _leaveGameSilently() async {
    final currentUser = ref.read(userProvider).value;
    if (currentUser != null) {
      await ref.read(gameRepositoryProvider).leaveGame(
            gameId: widget.gameId,
            uid: currentUser.uid,
          );
    }
  }

  Future<void> _shareGame(GameModel game) async {
    final String message = '캐치런 게임에 초대합니다! 🏃‍♂️\n\n'
        '🎮 게임 이름: ${game.title}\n'
        '🔢 게임 번호: ${game.gameCode}\n'
        '🔑 초대 코드: ${game.inviteCode}\n\n'
        '앱을 실행하고 코드 입력 또는 QR 스캔으로 참가하세요!';
    
    await Share.share(message, subject: '${game.title} 게임 초대');
  }

  Future<void> _handleExit() async {
    if (_isExiting) return;
    
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게임 나가기'),
        content: const Text('대기방에서 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );

    if (proceed == true && mounted) {
      setState(() => _isExiting = true);
      await _leaveGameSilently();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(gameRepositoryProvider).watchGame(widget.gameId);
    final participantsAsync = ref.watch(gameRepositoryProvider).watchParticipants(widget.gameId);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        _handleExit();
      },
      child: StreamBuilder(
        stream: gameAsync,
        builder: (context, gameSnapshot) {
          if (gameSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final game = gameSnapshot.data;
          if (game == null || game.status == GameStatus.finished) {
            // 게임이 삭제되었거나 방장이 나가서 종료된 경우
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isExiting) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('게임을 찾을 수 없거나 종료되었습니다.')),
                );
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            });
            return const Scaffold(body: Center(child: Text('게임을 종료합니다...')));
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(game.title),
              actions: [
                IconButton(
                  onPressed: () => _shareGame(game),
                  icon: const Icon(Icons.share),
                ),
              ],
            ),
            body: SafeArea(
              bottom: true,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('게임 참여 코드'),
                            Text(
                              game.gameCode,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('초대 코드: ${game.inviteCode}'),
                            const SizedBox(height: 16),
                            if (game.joinQrEnabled)
                              QrImageView(
                                data: 'catchrun:${game.id}:${game.joinQrToken}',
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.white,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: StreamBuilder(
                      stream: participantsAsync,
                      builder: (context, partSnapshot) {
                        final participants = partSnapshot.data ?? [];
                        final currentUser = ref.watch(userProvider).value;
  
                        return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              '참여 인원: ${participants.length}명',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: participants.length,
                              itemBuilder: (context, index) {
                                final p = participants[index];
                                return ListTile(
                                  leading: CircleAvatar(child: Text(p.nicknameSnapshot[0])),
                                  title: Text(p.nicknameSnapshot),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (p.uid == currentUser?.uid) const Chip(label: Text('나')),
                                      if (p.uid == game.hostUid) const Icon(Icons.star, color: Colors.amber),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Consumer(
                      builder: (context, ref, child) {
                        final currentUser = ref.watch(userProvider).value;
                        if (game.hostUid == currentUser?.uid) {
                          return FilledButton(
                            onPressed: () {},
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                            child: const Text('게임 시작'),
                          );
                        }
                        return const Text('방장이 게임을 시작하기를 기다리는 중...');
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
