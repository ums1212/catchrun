import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:go_router/go_router.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  final String gameId;
  final bool isCop;

  const QrScanScreen({
    super.key,
    required this.gameId,
    required this.isCop,
  });

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  bool _isProcessing = false;
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        setState(() => _isProcessing = true);
        await _controller.stop(); // 스캐너 일시 정지
        await _processQrData(code);
        if (mounted) {
          setState(() => _isProcessing = false);
          if (!_isProcessing) await _controller.start(); 
        }
        break;
      }
    }
  }

  Future<void> _processQrData(String data) async {
    final parts = data.split(':');
    if (parts.length != 3 || parts[0] != 'catchrun') {
      _showError('잘못된 QR 데이터 형식');
      return;
    }

    final targetGameId = parts[1];
    final targetUid = parts[2];

    if (targetGameId != widget.gameId) {
      _showError('타 게임 데이터 감지됨');
      return;
    }

    final currentUser = ref.read(userProvider).value;
    if (currentUser == null) return;

    if (targetUid == currentUser.uid) {
      _showError('본인 스캔 금지');
      return;
    }

    try {
      if (widget.isCop) {
        await ref.read(gameRepositoryProvider).catchRobber(
          gameId: widget.gameId,
          copUid: currentUser.uid,
          robberUid: targetUid,
        );
        _showSuccess('대상 체포 완료');
      } else {
        await ref.read(gameRepositoryProvider).rescueRobber(
          gameId: widget.gameId,
          rescuerUid: currentUser.uid,
          jailedUid: targetUid,
        );
        _showSuccess('아군 석방 완료');
      }
      
      if (mounted && context.canPop()) {
        context.pop();
      }

    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '').toUpperCase();
      _showError(message);
    }
  }

  void _showError(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _HudText(message, fontSize: 13, color: Colors.white),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _HudText(message, fontSize: 13, color: Colors.white),
        backgroundColor: Colors.greenAccent.withValues(alpha: 0.8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isCop ? Colors.blueAccent : Colors.redAccent;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: _HudText(
          widget.isCop ? '스캔: 도둑 체포' : '스캔: 아군 구출',
          color: themeColor,
          fontSize: 18,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
            controller: _controller,
          ),

          // HUD Scanner Frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: _GradientBorder(
                  width: 2,
                  gradient: LinearGradient(
                    colors: [
                      themeColor,
                      themeColor.withValues(alpha: 0.2),
                      themeColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Corneraccents logic could be added here for more "scifi" look
                  Positioned(
                    top: 0, left: 0,
                    child: Container(width: 20, height: 20, decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: themeColor, width: 4), left: BorderSide(color: themeColor, width: 4)),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(24)),
                    )),
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: Container(width: 20, height: 20, decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: themeColor, width: 4), right: BorderSide(color: themeColor, width: 4)),
                      borderRadius: const BorderRadius.only(topRight: Radius.circular(24)),
                    )),
                  ),
                  Positioned(
                    bottom: 0, left: 0,
                    child: Container(width: 20, height: 20, decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: themeColor, width: 4), left: BorderSide(color: themeColor, width: 4)),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24)),
                    )),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(width: 20, height: 20, decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: themeColor, width: 4), right: BorderSide(color: themeColor, width: 4)),
                      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(24)),
                    )),
                  ),
                  // Scanning animation could be added here
                ],
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: themeColor),
                    const SizedBox(height: 20),
                    _HudText('처리 중...', color: themeColor),
                  ],
                ),
              ),
            ),

          Positioned(
            bottom: 60,
            left: 30,
            right: 30,
            child: _GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _HudText(
                widget.isCop ? '대상의 식별 코드를 프레임에 맞추세요' : '아군의 식별 코드를 프레임에 맞추세요',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// HUD WIDGETS
class _HudText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final Color? color;
  final double? letterSpacing;
  final FontWeight? fontWeight;
  final TextStyle? style;

  const _HudText(
    this.text, {
    this.fontSize,
    this.color,
    this.letterSpacing,
    this.fontWeight,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: fontSize ?? style?.fontSize ?? 14,
        color: color ?? style?.color ?? Colors.white,
        fontWeight: fontWeight ?? style?.fontWeight ?? FontWeight.bold,
        letterSpacing: letterSpacing ?? style?.letterSpacing ?? 1.0,
        shadows: [
          Shadow(
            color: (color ?? style?.color ?? Colors.white).withValues(alpha: 0.5),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassContainer({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GradientBorder extends BoxBorder {
  final Gradient gradient;
  final double width;

  const _GradientBorder({required this.gradient, this.width = 1.0});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  bool get isUniform => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
    TextDirection? textDirection,
  }) {
    final Paint paint = Paint()
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..shader = gradient.createShader(rect);

    if (borderRadius != null) {
      canvas.drawRRect(borderRadius.toRRect(rect).deflate(width / 2), paint);
    } else {
      canvas.drawRect(rect.deflate(width / 2), paint);
    }
  }

  @override
  ShapeBorder scale(double t) =>
      _GradientBorder(gradient: gradient, width: width * t);

  @override
  BorderSide get bottom => BorderSide.none;
  @override
  BorderSide get top => BorderSide.none;
}
