import 'package:catchrun/core/models/game_model.dart';
import 'package:catchrun/core/models/participant_model.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catchrun/core/widgets/hud_text.dart';
import 'package:catchrun/core/widgets/glass_container.dart';
import 'package:catchrun/core/widgets/scifi_button.dart';
import 'package:catchrun/core/widgets/hud_section_header.dart';
import 'package:go_router/go_router.dart';

class ResultScreen extends ConsumerWidget {
  final String gameId;

  const ResultScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(watchGameProvider(gameId));
    final participantsAsync = ref.watch(watchParticipantsProvider(gameId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const HudText(
          '작전 결과',
          fontSize: 20,
          letterSpacing: 2,
          color: Colors.cyanAccent,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: gameAsync.when(
        data: (game) {
          if (game == null) {
            return const Center(
              child: HudText('게임을 찾을 수 없습니다.', color: Colors.white70),
            );
          }
          return participantsAsync.when(
            data: (participants) => _buildResultContent(context, game, participants),
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
            error: (err, stack) => Center(
              child: HudText('오류: $err', color: Colors.redAccent),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
        error: (err, stack) => Center(
          child: HudText('오류: $err', color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildResultContent(BuildContext context, GameModel game, List<ParticipantModel> participants) {
    final winnerColor = game.winnerRole == ParticipantRole.cop ? Colors.blueAccent : Colors.redAccent;
    final winnerText = game.winnerRole == ParticipantRole.cop ? '경찰 승리!' : '도둑 승리!';

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

    return OrientationBuilder(
      builder: (context, orientation) {
        final backgroundImage = orientation == Orientation.portrait
            ? 'assets/image/profile_setting_portrait.png'
            : 'assets/image/profile_setting_landscape.png';

        return Stack(
          children: [
            // 1. Background
            Positioned.fill(
              child: Image.asset(backgroundImage, fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // 2. Content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  children: [
                    // Win Banner
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded, 
                            color: winnerColor, 
                            size: 80,
                            shadows: [
                              Shadow(color: winnerColor.withValues(alpha: 0.8), blurRadius: 20),
                            ],
                          ),
                          const SizedBox(height: 24),
                          HudText(
                            winnerText,
                            fontSize: 36,
                            color: winnerColor,
                            letterSpacing: 4,
                          ),
                          const SizedBox(height: 12),
                          HudText(
                            '작전이 종료되었습니다',
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 특별 칭호
                    HudSectionHeader(title: '특별 칭호'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (mvp != null) _buildTitleCard('⭐ MVP', mvp.nicknameSnapshot, winnerColor),
                        if (mostCatches != null) _buildTitleCard('🏅 검거왕', mostCatches.nicknameSnapshot, Colors.blueAccent),
                        if (mostRescues != null) _buildTitleCard('🗝 구출왕', mostRescues.nicknameSnapshot, Colors.orangeAccent),
                        if (longestSurvival != null) _buildTitleCard('⏱ 불사조', longestSurvival.nicknameSnapshot, Colors.greenAccent),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // 리더보드
                    HudSectionHeader(title: '최종 순위표'),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedParticipants.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final p = sortedParticipants[index];
                        return _buildRankingItem(p, index + 1);
                      },
                    ),

                    const SizedBox(height: 60),

                    // Action Button
                    SciFiButton(
                      text: '홈으로 돌아가기',
                      icon: Icons.home_rounded,
                      onPressed: () => context.go('/home'),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTitleCard(String title, String name, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HudText(title, fontSize: 12, color: color),
          const SizedBox(height: 6),
          HudText(name, fontSize: 14, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildRankingItem(ParticipantModel p, int rank) {
    final isCop = p.role == ParticipantRole.cop;
    final rankColor = rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey[300]! : (rank == 3 ? Colors.orange[300]! : Colors.white24));

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: rank <= 3 ? rankColor : Colors.white10,
                width: 1.5,
              ),
              boxShadow: rank <= 3 ? [
                BoxShadow(color: rankColor.withValues(alpha: 0.3), blurRadius: 8),
              ] : [],
            ),
            alignment: Alignment.center,
            child: HudText(
              '$rank',
              fontSize: 16,
              color: rank <= 3 ? rankColor : Colors.white54,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HudText(p.nicknameSnapshot, fontSize: 16),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCop ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isCop ? Colors.blueAccent.withValues(alpha: 0.4) : Colors.redAccent.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: HudText(
                        isCop ? '경찰' : '도둑',
                        fontSize: 10,
                        color: isCop ? Colors.blueAccent : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              HudText('${p.score}', fontSize: 18, color: Colors.cyanAccent),
              const HudText('POINTS', fontSize: 10, color: Colors.white38, fontWeight: FontWeight.normal),
            ],
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
