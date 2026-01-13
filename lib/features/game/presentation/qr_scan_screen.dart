import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:catchrun/core/providers/app_bar_provider.dart';
import 'package:catchrun/core/widgets/hud_text.dart';
import 'package:catchrun/core/widgets/glass_container.dart';
import 'package:catchrun/core/widgets/gradient_border.dart';

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
  void initState() {
    super.initState();
    // AppBar 초기 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateAppBar();
      }
    });
  }

  void _updateAppBar() {
    final themeColor = widget.isCop ? Colors.blueAccent : Colors.redAccent;
    ref.read(appBarProvider.notifier).state = AppBarConfig(
      title: widget.isCop ? '스캔: 도둑 체포' : '스캔: 아군 구출',
      centerTitle: true,
      titleColor: themeColor,
    );
  }

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
        await _controller.stop();
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
      
      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }

    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '').toUpperCase();
      _showError(message);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: HudText(message, fontSize: 13, color: Colors.white),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: HudText(message, fontSize: 13, color: Colors.white),
          backgroundColor: Colors.greenAccent.withValues(alpha: 0.8),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isCop ? Colors.blueAccent : Colors.redAccent;

    return Stack(
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
              border: GradientBorder(
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
                  HudText('처리 중...', color: themeColor),
                ],
              ),
            ),
          ),

        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: kToolbarHeight),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: HudText(
                    widget.isCop ? '대상의 식별 코드를 프레임에 맞추세요' : '아군의 식별 코드를 프레임에 맞추세요',
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
