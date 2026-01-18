import 'package:flutter/material.dart';
import 'package:catchrun/core/widgets/hud_text.dart';
import 'package:catchrun/core/widgets/glass_container.dart';
import 'package:catchrun/core/models/participant_model.dart';

class ResultTitleCard extends StatelessWidget {
  final String title;
  final String name;
  final Color titleColor;

  const ResultTitleCard({
    super.key,
    required this.title,
    required this.name,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HudText(title, fontSize: 12, color: titleColor),
          const SizedBox(height: 6),
          HudText(name, fontSize: 14, color: Colors.white),
        ],
      ),
    );
  }
}

class ResultRankingItem extends StatelessWidget {
  final ParticipantModel participant;
  final int rank;

  const ResultRankingItem({
    super.key,
    required this.participant,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final isCop = participant.role == ParticipantRole.cop;
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
                HudText(participant.nicknameSnapshot, fontSize: 16),
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
              HudText('${participant.score}', fontSize: 18, color: Colors.cyanAccent),
              const HudText('POINTS', fontSize: 10, color: Colors.white38, fontWeight: FontWeight.normal),
            ],
          ),
        ],
      ),
    );
  }
}
