import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:catchrun/core/widgets/hud_text.dart';

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
