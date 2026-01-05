import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:catchrun/core/models/game_model.dart';
import 'package:catchrun/core/models/participant_model.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:go_router/go_router.dart';

class PrisonScreen extends ConsumerWidget {
  final String gameId;

  const PrisonScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userProvider).value;
    final gameAsync = ref.watch(gameRepositoryProvider).watchGame(gameId);
    
    return StreamBuilder<GameModel?>(
      stream: gameAsync,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final game = snapshot.data!;
        final participantsAsync = ref.watch(gameRepositoryProvider).watchParticipants(gameId);
        
        return StreamBuilder<List<ParticipantModel>>(
          stream: participantsAsync,
          builder: (context, partSnapshot) {
            final participants = partSnapshot.data ?? [];
            final myParticipant = participants.firstWhere(
              (p) => p.uid == currentUser?.uid,
              orElse: () => ParticipantModel(uid: '', nicknameSnapshot: '', joinedAt: DateTime.now(), stats: ParticipantStats()),
            );

            // 석방 감지 시 다시 플레이 화면으로
            if (myParticipant.state == RobberState.free && myParticipant.uid.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.go('/play/$gameId');
                }
              });
            }

            final qrData = 'catchrun:${game.id}:${currentUser?.uid}';

            return Scaffold(
          backgroundColor: Colors.grey[900],
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Icon(
                  Icons.lock_person,
                  size: 80,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 24),
                const Text(
                  '현재 수감되었습니다!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    '지정된 감옥 위치에 머물러야 하며, 이동이 불가합니다. 동료가 QR 코드를 스캔해주면 석방될 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
                const Spacer(),
                
                // 내 QR 코드
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 240.0,
                    gapless: false,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '내 구출용 QR 코드',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const Spacer(),
                
                // 게임 정보 요약
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('남은 도둑', '${game.counts.robbersFree}', Colors.greenAccent),
                      _buildStatItem('수감 인원', '${game.counts.robbersJailed}', Colors.redAccent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
