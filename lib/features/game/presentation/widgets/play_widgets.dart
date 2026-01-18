import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:catchrun/core/widgets/hud_text.dart';
import 'package:catchrun/features/game/data/game_repository.dart';

class MyQrDialogContent extends StatelessWidget {
  final String gameId;
  final String uid;

  const MyQrDialogContent({
    super.key,
    required this.gameId,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const HudText(
          '구출을 위해 아군에게 보여주거나\n식별을 위해 경찰에게 보여주세요.',
          fontWeight: FontWeight.normal,
          fontSize: 12,
          color: Colors.white70,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(
            data: 'catchrun:$gameId:$uid',
            version: QrVersions.auto,
            size: 200.0,
          ),
        ),
      ],
    );
  }
}
class ActivityLogDialogContent extends ConsumerWidget {
  final String gameId;

  const ActivityLogDialogContent({
    super.key,
    required this.gameId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsStream = ref.watch(gameRepositoryProvider).watchAllEvents(gameId);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
        minWidth: double.infinity,
      ),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
            );
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: HudText('활동 내역이 없습니다.', fontSize: 13, color: Colors.white54),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            itemCount: events.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.white.withValues(alpha: 0.1),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final event = events[index];
              final payload = event['payload'] as Map<String, dynamic>?;
              final message = payload?['message'] as String? ?? '알 수 없는 활동';
              final createdAt = event['createdAt'] as Timestamp?;
              final timeStr = createdAt != null
                  ? '${createdAt.toDate().hour.toString().padLeft(2, '0')}:${createdAt.toDate().minute.toString().padLeft(2, '0')}:${createdAt.toDate().second.toString().padLeft(2, '0')}'
                  : '--:--:--';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HudText(
                      '[$timeStr]',
                      fontSize: 10,
                      color: Colors.cyanAccent.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: HudText(
                        message,
                        fontSize: 12,
                        textAlign: TextAlign.start,
                        fontWeight: FontWeight.normal,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
