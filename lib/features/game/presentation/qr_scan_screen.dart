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

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        setState(() => _isProcessing = true);
        await _processQrData(code);
        if (mounted) setState(() => _isProcessing = false);
        break;
      }
    }
  }

  Future<void> _processQrData(String data) async {
    // 포맷: catchrun:{gameId}:{uid}
    final parts = data.split(':');
    if (parts.length != 3 || parts[0] != 'catchrun') {
      _showError('유효하지 않은 QR 코드입니다.');
      return;
    }

    final targetGameId = parts[1];
    final targetUid = parts[2];

    if (targetGameId != widget.gameId) {
      _showError('다른 게임의 플레이어입니다.');
      return;
    }

    final currentUser = ref.read(userProvider).value;
    if (currentUser == null) return;

    if (targetUid == currentUser.uid) {
      _showError('본인의 QR 코드는 스캔할 수 없습니다.');
      return;
    }

    try {
      if (widget.isCop) {
        // 경찰: 체포하기
        await ref.read(gameRepositoryProvider).catchRobber(
          gameId: widget.gameId,
          copUid: currentUser.uid,
          robberUid: targetUid,
        );
        _showSuccess('체포 성공!');
      } else {
        // 도둑: 구출하기
        await ref.read(gameRepositoryProvider).rescueRobber(
          gameId: widget.gameId,
          rescuerUid: currentUser.uid,
          jailedUid: targetUid,
        );
        _showSuccess('구출 성공!');
      }
      
      if (mounted) context.pop();
    } catch (e) {
      _showError('처리 중 오류가 발생했습니다: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCop ? '도둑 체포 (QR)' : '동료 구출 (QR)'),
        backgroundColor: widget.isCop ? Colors.blue : Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
            controller: MobileScannerController(
              facing: CameraFacing.back,
              torchEnabled: false,
            ),
          ),
          // 스캔 영역 가이드 UI
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  widget.isCop ? '도둑의 QR 코드를 비춰주세요' : '수감된 도둑의 QR 코드를 비춰주세요',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
