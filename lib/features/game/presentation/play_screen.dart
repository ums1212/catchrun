import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:catchrun/core/models/game_model.dart';
import 'package:catchrun/core/models/participant_model.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:go_router/go_router.dart';

class PlayScreen extends ConsumerStatefulWidget {
  final String gameId;
  const PlayScreen({super.key, required this.gameId});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _checkEndConditions();
    });
  }

  void _checkEndConditions() {
    final gameAsync = ref.read(gameRepositoryProvider).watchGame(widget.gameId);
    gameAsync.first.then((game) {
      if (game == null || game.status != GameStatus.playing) return;

      final currentUser = ref.read(userProvider).value;
      if (game.hostUid != currentUser?.uid) return;

      // 1. 시간 종료 체크
      if (game.endsAt != null && DateTime.now().isAfter(game.endsAt!)) {
        ref.read(gameRepositoryProvider).finishGame(game.id);
        return;
      }

      // 2. 도둑 전원 수감 체크
      if (game.counts.robbers > 0 && game.counts.robbersFree == 0) {
        ref.read(gameRepositoryProvider).finishGame(game.id);
      }
    });
    
    setState(() {});
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(gameRepositoryProvider).watchGame(widget.gameId);
    final participantsAsync = ref.watch(gameRepositoryProvider).watchParticipants(widget.gameId);
    final currentUser = ref.watch(userProvider).value;

    return StreamBuilder<GameModel?>(
      stream: gameAsync,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final game = snapshot.data!;
        
        if (game.status == GameStatus.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('게임이 종료되었습니다!')),
              );
              context.go('/home'); // 결과 화면(Sprint 6) 전까지는 홈으로
            }
          });
          return const Scaffold(body: Center(child: Text('게임이 종료되었습니다.')));
        }
        return StreamBuilder<List<ParticipantModel>>(
          stream: participantsAsync,
          builder: (context, partSnapshot) {
            final participants = partSnapshot.data ?? [];
            final myParticipant = participants.firstWhere(
              (p) => p.uid == currentUser?.uid,
              orElse: () => ParticipantModel(uid: '', nicknameSnapshot: '', joinedAt: DateTime.now(), stats: ParticipantStats()),
            );

            final isCop = myParticipant.role == ParticipantRole.cop;
            final themeColor = isCop ? Colors.blue : Colors.red;

            // 남은 시간 계산
            if (game.endsAt != null) {
              _remainingTime = game.endsAt!.difference(DateTime.now());
              if (_remainingTime.isNegative) _remainingTime = Duration.zero;
            }

            return Scaffold(
              backgroundColor: themeColor.withOpacity(0.05),
              appBar: AppBar(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                title: Text(isCop ? '경찰 (추격 중)' : '도둑 (생존 중)'),
                centerTitle: true,
                automaticallyImplyLeading: false,
              ),
              body: Column(
                children: [
                  // 상단 타이머 섹션
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '남은 시간',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        Text(
                          _formatDuration(_remainingTime),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 게임 상태 카드
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 21),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('전체 도둑', '${game.counts.robbers}'),
                            _buildStatItem('수감됨', '${game.counts.robbersJailed}', color: Colors.red),
                            _buildStatItem('탈출 중', '${game.counts.robbersFree}', color: Colors.green),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // 역할별 안내 문구
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      isCop 
                        ? '도둑을 잡고 QR 코드를 스캔하세요!' 
                        : (myParticipant.state == RobberState.jailed 
                            ? '수감되었습니다! 다른 도둑이 구출해주길 기다리세요.' 
                            : '경찰을 피해 생존하세요!'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
