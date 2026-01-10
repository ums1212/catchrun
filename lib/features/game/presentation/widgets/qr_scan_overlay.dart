import 'package:flutter/material.dart';
import 'package:catchrun/core/widgets/hud_text.dart';
import 'package:catchrun/core/widgets/gradient_border.dart';

/// QR Scan Overlay Widget
class QrScanOverlay extends StatelessWidget {
  const QrScanOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Outer darker area
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.5),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Neon Frame
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: const GradientBorder(
                width: 3,
                gradient: LinearGradient(
                  colors: [Colors.cyanAccent, Colors.blueAccent],
                ),
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.2,
          left: 0,
          right: 0,
          child: const Center(
            child: HudText(
              '초대 QR 코드를 스캔하세요',
              fontSize: 16,
              color: Colors.cyanAccent,
            ),
          ),
        ),
      ],
    );
  }
}
