import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:catchrun/core/widgets/glass_container.dart';
import 'package:catchrun/core/widgets/hud_text.dart';
import 'package:catchrun/core/models/game_model.dart';
import 'dart:math' as math;

class LobbyGameCodeCard extends StatelessWidget {
  final GameModel game;
  final double expandRatio; // 1.0 (펼쳐짐) ~ 0.0 (접힘)
  final VoidCallback? onTap;

  const LobbyGameCodeCard({
    super.key,
    required this.game,
    this.expandRatio = 1.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: EdgeInsets.symmetric(
          horizontal: 24, 
          vertical: 4 + (12 * expandRatio),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더: 미션 식별 코드 (상시 노출)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HudText('미션 식별 코드', fontSize: 12, color: Colors.white70),
                const SizedBox(width: 8),
                Transform.rotate(
                  angle: (1.0 - expandRatio) * math.pi,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ],
            ),
            
            // 동적 크기 조절 영역
            ClipRect(
              child: Align(
                heightFactor: math.max(0.01, expandRatio), // 0일 때 히트테스트 이슈 방지를 위해 최소값 설정
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: expandRatio * expandRatio,
                  child: Column(
                    children: [
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
                        SizedBox(height: 16 * expandRatio),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: 'catchrun:${game.id}:${game.joinQrToken}',
                            version: QrVersions.auto,
                            size: 140.0 * expandRatio,
                          ),
                        ),
                      ],
                      SizedBox(height: 8 * expandRatio),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LobbyGameCodeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final GameModel game;
  final double expandedHeight;
  final double collapsedHeight;
  final VoidCallback? onToggle;

  LobbyGameCodeHeaderDelegate({
    required this.game,
    this.expandedHeight = 400.0,
    this.collapsedHeight = 84.0, 
    this.onToggle,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // shrinkOffset에 따른 확장 비율 계산
    final double expandRatio = math.max(0.0, 1.0 - (shrinkOffset / (expandedHeight - collapsedHeight)));
    
    // 상단 패딩 조절
    final double topPadding = 4 + (12 * expandRatio);

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 0),
      alignment: Alignment.topCenter,
      child: LobbyGameCodeCard(
        game: game,
        expandRatio: expandRatio > 0.05 ? expandRatio : 0.0, // 완전히 접혔을 때를 더 확실히 처리
        onTap: onToggle,
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  bool shouldRebuild(covariant LobbyGameCodeHeaderDelegate oldDelegate) {
    return game.id != oldDelegate.game.id || 
           game.joinQrEnabled != oldDelegate.game.joinQrEnabled ||
           game.gameCode != oldDelegate.game.gameCode ||
           expandedHeight != oldDelegate.expandedHeight ||
           collapsedHeight != oldDelegate.collapsedHeight ||
           onToggle != oldDelegate.onToggle;
  }
}
