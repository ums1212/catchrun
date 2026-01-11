import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:catchrun/core/widgets/glass_container.dart';
import 'package:catchrun/core/widgets/hud_text.dart';
import 'package:catchrun/core/models/game_model.dart';

class LobbyGameCodeCard extends StatelessWidget {
  final GameModel game;

  const LobbyGameCodeCard({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const HudText('미션 식별 코드', fontSize: 12, color: Colors.white70),
          const SizedBox(height: 8),
          HudText(
            game.gameCode,
            fontSize: 32,
            letterSpacing: 6,
            color: Colors.cyanAccent,
          ),
          const SizedBox(height: 8),
          HudText(
            '초대 코드: ${game.inviteCode}',
            fontSize: 14,
            color: Colors.white54,
            fontWeight: FontWeight.normal,
          ),
          if (game.joinQrEnabled) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: QrImageView(
                data: 'catchrun:${game.id}:${game.joinQrToken}',
                version: QrVersions.auto,
                size: 140.0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
