import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:catchrun/core/widgets/hud_text.dart';
import 'package:catchrun/core/models/participant_model.dart';

class LobbyParticipantTile extends StatelessWidget {
  final ParticipantModel participant;
  final bool isCurrentUser;
  final bool isHost;
  final bool isRoomHost;
  final VoidCallback? onTap;

  const LobbyParticipantTile({
    super.key,
    required this.participant,
    required this.isCurrentUser,
    required this.isHost,
    required this.isRoomHost,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCop = participant.role == ParticipantRole.cop;
    final color = isCop ? Colors.blueAccent : Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ListTile(
              onTap: onTap,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/image/profile${participant.avatarSeedSnapshot ?? '1'}.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Text(
                      isCop ? '👮' : '🏃',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ),
              title: Row(
                children: [
                  HudText(participant.nicknameSnapshot, fontSize: 16),
                  if (isCurrentUser) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                      ),
                      child: const HudText('본인', fontSize: 10, color: Colors.cyanAccent),
                    ),
                  ],
                ],
              ),
              subtitle: HudText(
                isCop ? 'TACTICAL UNIT (POLICE)' : 'TARGET VESSEL (ROBBER)',
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.normal,
              ),
              trailing: isHost 
                ? const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 24)
                : null,
            ),
          ),
        ),
      ),
    );
  }
}
