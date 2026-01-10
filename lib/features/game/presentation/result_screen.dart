import 'package:catchrun/core/models/game_model.dart';
import 'package:catchrun/core/models/participant_model.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:catchrun/core/widgets/common_button.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ResultScreen extends ConsumerWidget {
  final String gameId;

  const ResultScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(watchGameProvider(gameId));
    final participantsAsync = ref.watch(watchParticipantsProvider(gameId));

    return Scaffold(
      body: gameAsync.when(
        data: (game) {
          if (game == null) {
            return const Center(child: Text('게임을 찾을 수 없습니다.'));
          }
          return participantsAsync.when(
            data: (participants) => _buildResultContent(context, game, participants),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('오류: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('오류: $err')),
      ),
    );
  }

  Widget _buildResultContent(BuildContext context, GameModel game, List<ParticipantModel> participants) {
    final theme = Theme.of(context);
    final winnerColor = game.winnerRole == ParticipantRole.cop ? Colors.blue : Colors.red;
    final winnerText = game.winnerRole == ParticipantRole.cop ? '경찰 승리!' : '도둑 승리!';

    // 정렬된 참가자 리스트 (점수 내림차순)
    final sortedParticipants = List<ParticipantModel>.from(participants)
      ..sort((a, b) => b.score.compareTo(a.score));

    // 특별 칭호 산출
    final mvp = sortedParticipants.isNotEmpty ? sortedParticipants.first : null;
    
    ParticipantModel? mostCatches;
    int maxCatches = 0;
    for (var p in participants) {
      if (p.role == ParticipantRole.cop && p.stats.catches > maxCatches) {
        maxCatches = p.stats.catches;
        mostCatches = p;
      }
    }

    ParticipantModel? mostRescues;
    int maxRescues = 0;
    for (var p in participants) {
      if (p.role == ParticipantRole.robber && p.stats.rescues > maxRescues) {
        maxRescues = p.stats.rescues;
        mostRescues = p;
      }
    }

    ParticipantModel? longestSurvival;
    int maxSurvival = 0;
    for (var p in participants) {
      if (p.role == ParticipantRole.robber && p.stats.survivalSec > maxSurvival) {
        maxSurvival = p.stats.survivalSec;
        longestSurvival = p;
      }
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. 승리 배너
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 60),
            decoration: BoxDecoration(
              color: winnerColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 80),
                const SizedBox(height: 16),
                Text(
                  winnerText,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. 특별 칭호 섹션
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('특별 칭호', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (mvp != null) _buildTitleCard('⭐ MVP', mvp.nicknameSnapshot, winnerColor),
                    if (mostCatches != null) _buildTitleCard('🏅 검거왕', mostCatches.nicknameSnapshot, Colors.blue),
                    if (mostRescues != null) _buildTitleCard('🗝 구출왕', mostRescues.nicknameSnapshot, Colors.orange),
                    if (longestSurvival != null) _buildTitleCard('⏱ 불사조', longestSurvival.nicknameSnapshot, Colors.green),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 3. 리더보드 섹션
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('순위표', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedParticipants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = sortedParticipants[index];
                    return _buildRankingItem(p, index + 1);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // 4. 홈으로 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CommonButton(
              label: '홈으로 돌아가기',
              onPressed: () => context.go('/home'),
            ),
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildTitleCard(String title, String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRankingItem(ParticipantModel p, int rank) {
    final isCop = p.role == ParticipantRole.cop;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3 ? Colors.amber : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            p.nicknameSnapshot,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isCop ? Colors.blue[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isCop ? '경찰' : '도둑',
              style: TextStyle(
                fontSize: 10,
                color: isCop ? Colors.blue : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '${p.score} 점',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// Provider extensions for watching
final watchGameProvider = StreamProvider.family<GameModel?, String>((ref, id) {
  return ref.watch(gameRepositoryProvider).watchGame(id);
});

final watchParticipantsProvider = StreamProvider.family<List<ParticipantModel>, String>((ref, id) {
  return ref.watch(gameRepositoryProvider).watchParticipants(id);
});
