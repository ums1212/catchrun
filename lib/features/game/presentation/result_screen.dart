import 'package:catchrun/core/models/game_model.dart';
import 'package:catchrun/core/models/participant_model.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catchrun/core/widgets/hud_text.dart';
import 'package:catchrun/core/widgets/glass_container.dart';
import 'package:catchrun/core/widgets/scifi_button.dart';
import 'package:catchrun/core/widgets/hud_section_header.dart';
import 'package:catchrun/features/game/presentation/widgets/result_widgets.dart';
import 'package:catchrun/features/game/presentation/widgets/play_widgets.dart';
import 'package:catchrun/core/widgets/hud_dialog.dart';
import 'package:go_router/go_router.dart';

class ResultScreen extends ConsumerWidget {
  final String gameId;

  const ResultScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(watchGameProvider(gameId));
    final participantsAsync = ref.watch(watchParticipantsProvider(gameId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
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
          // 뒤로가기 버튼이 자동으로 생기지 않도록 설정 (이미 팝스코프로 제어 중이므로)
          automaticallyImplyLeading: false,
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
                        if (mvp != null) ResultTitleCard(title: '⭐ MVP', name: mvp.nicknameSnapshot, avatarSeed: mvp.avatarSeedSnapshot, titleColor: winnerColor),
                        if (mostCatches != null) ResultTitleCard(title: '🏅 검거왕', name: mostCatches.nicknameSnapshot, avatarSeed: mostCatches.avatarSeedSnapshot, titleColor: Colors.blueAccent),
                        if (mostRescues != null) ResultTitleCard(title: '🗝 구출왕', name: mostRescues.nicknameSnapshot, avatarSeed: mostRescues.avatarSeedSnapshot, titleColor: Colors.orangeAccent),
                        if (longestSurvival != null) ResultTitleCard(title: '⏱ 불사조', name: longestSurvival.nicknameSnapshot, avatarSeed: longestSurvival.avatarSeedSnapshot, titleColor: Colors.greenAccent),
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
                        return ResultRankingItem(participant: p, rank: index + 1);
                      },
                    ),

                    const SizedBox(height: 60),

                    const SizedBox(height: 20),
                    SciFiButton(
                      text: '활동 로그 확인',
                      isOutlined: true,
                      onPressed: () => _showActivityLogDialog(context),
                    ),

                    const SizedBox(height: 40),

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

  void _showActivityLogDialog(BuildContext context) {
    HudDialog.show(
      context: context,
      title: '활동 로그 확인',
      titleColor: Colors.cyanAccent,
      content: ActivityLogDialogContent(gameId: gameId),
      actions: [
        SciFiButton(
          text: '닫기',
          height: 45,
          fontSize: 14,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ],
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
