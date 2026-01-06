import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class JoinGameScreen extends ConsumerStatefulWidget {
  const JoinGameScreen({super.key});

  @override
  ConsumerState<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends ConsumerState<JoinGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gameCodeController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _isLoading = false;
  bool _isScanning = false; // 기본값 false로 시작해서 권한 확인 후 true로 변경
  bool _isPermissionDenied = false;

  @override
  void dispose() {
    _gameCodeController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinGame() async {
    if (!_formKey.currentState!.validate()) return;
    _performJoin(() => ref.read(gameRepositoryProvider).joinGameByCode(
          gameCode: _gameCodeController.text,
          inviteCode: _inviteCodeController.text,
          user: ref.read(userProvider).value!,
        ));
  }

  Future<void> _checkCameraPermission() async {
    // 1. 현재 권한 상태 확인
    final status = await Permission.camera.status;
    debugPrint('DEBUG: Current Camera Status: $status');

    // 이미 허용된 경우
    if (status.isGranted) {
      _setScanningState(true);
      return;
    }

    // 영구적으로 거부된 경우 (이미 '다시 묻지 않음' 선택 상태)
    if (status.isPermanentlyDenied) {
      debugPrint('DEBUG: Permanently Denied detected - showing dialog');
      _setScanningState(false, denied: true);
      _showPermissionDialog();
      return;
    }

    // 2. 권한 요청 시도 (최초 실행 또는 1회 거절 상태 등)
    // 이 단계에서 시스템 팝업이 나타납니다.
    debugPrint('DEBUG: Requesting permission...');
    final result = await Permission.camera.request();
    debugPrint('DEBUG: Request Result: $result');

    if (result.isGranted) {
      _setScanningState(true);
    } else if (result.isPermanentlyDenied) {
      // 사용자가 '거부 및 다시 묻지 않음'을 선택한 경우
      _setScanningState(false, denied: true);
      _showPermissionDialog();
    } else {
      // 일반 거부 상태
      _setScanningState(false, denied: true);
      
      // 시스템 팝업이 더 이상 뜨지 않는 상태인지 최종 확인
      // (request 이후에도 여전히 rationale이 false라면 시스템이 팝업을 차단한 상태)
      final rationale = await Permission.camera.shouldShowRequestRationale;
      debugPrint('DEBUG: Post-request Rationale: $rationale');
      
      if (!rationale && mounted) {
        _showPermissionDialog();
      }

    }
  }

  void _setScanningState(bool scanning, {bool denied = false}) {
    setState(() {
      _isScanning = scanning;
      _isPermissionDenied = denied;
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카메라 권한 필요'),
        content: const Text('QR 코드 스캔을 위해 카메라 권한이 필요합니다. 설정 화면에서 권한을 허용해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await openAppSettings();
              if (mounted) {
                navigator.pop();
              }
            },

            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!_isScanning || _isLoading) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.startsWith('catchrun:')) {
        setState(() {
          _isScanning = false;
          _isLoading = true;
        });

        final parts = code.split(':');
        if (parts.length == 3) {
          final gameId = parts[1];
          final qrToken = parts[2];
          
          _performJoin(() => ref.read(gameRepositoryProvider).joinGameByQr(
                gameId: gameId,
                qrToken: qrToken,
                user: ref.read(userProvider).value!,
              ));
          return;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('유효하지 않은 QR 코드 형식입니다.')),
            );
            setState(() {
              _isLoading = false;
              _isScanning = true;
            });
          }
        }

      }
    }
  }

  Future<void> _performJoin(Future<String> Function() joinAction) async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(userProvider).value;
      if (user == null) throw Exception('사용자 정보를 찾을 수 없습니다.');

      final gameId = await joinAction();
      if (mounted) {
        context.pushReplacement('/lobby/$gameId');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('참가 중 오류 발생: $e')),
        );
        setState(() {
          _isLoading = false;
          _isScanning = true;
        });
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('게임 참가'),
          bottom: TabBar(
            onTap: (index) {
              if (index == 1) {
                _checkCameraPermission();
              } else {
                setState(() {
                  _isScanning = false;
                });
              }
            },
            tabs: const [
              Tab(icon: Icon(Icons.numbers), text: '코드 입력'),
              Tab(icon: Icon(Icons.qr_code_scanner), text: 'QR 스캔'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // 코드 입력 탭
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _gameCodeController,
                        decoration: const InputDecoration(
                          labelText: '게임 번호 (9자리)',
                          border: OutlineInputBorder(),
                          hintText: '예: 123456789',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => 
                            (value?.length != 9) ? '9자리 번호를 입력해주세요.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _inviteCodeController,
                        decoration: const InputDecoration(
                          labelText: '초대 코드 (6자리)',
                          border: OutlineInputBorder(),
                          hintText: '예: 123456',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => 
                            (value?.length != 6) ? '6자리 코드를 입력해주세요.' : null,
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: _isLoading ? null : _joinGame,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('게임 참가하기'),
                      ),
                    ],
                  ),
                ),
              ),
              // QR 스캔 탭
              Stack(
                children: [
                  if (_isScanning)
                    MobileScanner(
                      onDetect: _onDetect,
                    ),
                  if (_isPermissionDenied && !_isScanning)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('카메라 권한이 거부되었습니다.'),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _checkCameraPermission,
                            child: const Text('다시 시도 또는 설정 이동'),
                          ),
                        ],
                      ),
                    ),
                  if (_isScanning)
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
