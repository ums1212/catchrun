import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:catchrun/core/widgets/hud_text.dart';
import 'package:catchrun/core/widgets/glass_container.dart';
import 'package:catchrun/core/widgets/scifi_button.dart';
import 'package:catchrun/core/widgets/hud_section_header.dart';
import 'package:catchrun/core/widgets/hud_text_field.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:catchrun/core/widgets/hud_dialog.dart';
import 'package:catchrun/features/game/presentation/widgets/qr_scan_overlay.dart';

class JoinGameScreen extends ConsumerStatefulWidget {
  const JoinGameScreen({super.key});

  @override
  ConsumerState<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends ConsumerState<JoinGameScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _gameCodeController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  late TabController _tabController;
  bool _isLoading = false;
  bool _isScanning = false;
  bool _isPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _checkCameraPermission();
      } else {
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _gameCodeController.dispose();
    _inviteCodeController.dispose();
    _tabController.dispose();
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
    final status = await Permission.camera.status;
    if (status.isGranted) {
      _setScanningState(true);
      return;
    }

    if (status.isPermanentlyDenied) {
      _setScanningState(false, denied: true);
      _showPermissionDialog();
      return;
    }

    final result = await Permission.camera.request();
    if (result.isGranted) {
      _setScanningState(true);
    } else if (result.isPermanentlyDenied) {
      _setScanningState(false, denied: true);
      _showPermissionDialog();
    } else {
      _setScanningState(false, denied: true);
      final rationale = await Permission.camera.shouldShowRequestRationale;
      if (!rationale && mounted) {
        _showPermissionDialog();
      }
    }
  }

  void _setScanningState(bool scanning, {bool denied = false}) {
    if (!mounted) return;
    setState(() {
      _isScanning = scanning;
      _isPermissionDenied = denied;
    });
  }

  void _showPermissionDialog() {
    HudDialog.show(
      context: context,
      title: '카메라 권한 필요',
      contentText: 'QR 코드 스캔을 위해 카메라 권한이 필요합니다. 설정 화면에서 권한을 허용해주세요.',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: HudText('취소', color: Colors.white.withValues(alpha: 0.6)),
        ),
        SciFiButton(
          text: '설정 이동',
          height: 45,
          fontSize: 14,
          onPressed: () async {
            final navigator = Navigator.of(context);
            await openAppSettings();
            if (mounted) navigator.pop();
          },
        ),
      ],
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
              SnackBar(
                backgroundColor: Colors.redAccent,
                content: const HudText('유효하지 않은 QR 코드 형식입니다.'),
              ),
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
      if (!mounted) return;
      context.pushReplacement('/lobby/$gameId');

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: HudText('참가 중 오류 발생: $e'),
        ),
      );
        setState(() {
          _isLoading = false;
          _isScanning = true;
        });
      }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const HudText(
          '게임 참가',
          fontSize: 20,
          letterSpacing: 2,
          color: Colors.cyanAccent,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          indicatorWeight: 3,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(icon: Icon(Icons.numbers_rounded), text: '코드 입력'),
            Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'QR 스캔'),
          ],
        ),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final backgroundImage = orientation == Orientation.portrait
              ? 'assets/image/profile_setting_portrait.png'
              : 'assets/image/profile_setting_landscape.png';

          return SizedBox.expand(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(backgroundImage, fit: BoxFit.cover),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // TAB 1: CODE INPUT
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 10),
                              HudSectionHeader(title: '게임 코드 정보'),
                              const SizedBox(height: 24),
                              HudTextField(
                                controller: _gameCodeController,
                                labelText: '게임 번호 (9자리)',
                                hintText: '예: 123456789',
                                keyboardType: TextInputType.number,
                                validator: (value) => 
                                    (value?.length != 9) ? '9자리 번호를 입력해주세요.' : null,
                              ),
                              const SizedBox(height: 20),
                              HudTextField(
                                controller: _inviteCodeController,
                                labelText: '초대 코드 (6자리)',
                                hintText: '예: 123456',
                                keyboardType: TextInputType.number,
                                validator: (value) => 
                                    (value?.length != 6) ? '6자리 코드를 입력해주세요.' : null,
                              ),
                              const SizedBox(height: 48),
                              if (_isLoading)
                                const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                              else
                                SciFiButton(
                                  text: '게임 참가하기',
                                  icon: Icons.login_rounded,
                                  onPressed: _joinGame,
                                ),
                            ],
                          ),
                        ),
                      ),
                      // TAB 2: QR SCAN
                      Stack(
                        children: [
                          if (_isScanning)
                            MobileScanner(onDetect: _onDetect),
                          // QR Scan Overlay
                          if (_isScanning)
                            const QrScanOverlay(),
                          if (_isPermissionDenied && !_isScanning)
                            Center(
                              child: GlassContainer(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.cyanAccent),
                                    const SizedBox(height: 24),
                                    const HudText('카메라 권한이 거부되었습니다.', fontSize: 16),
                                    const SizedBox(height: 32),
                                    SciFiButton(
                                      text: '권한 설정 확인',
                                      onPressed: _checkCameraPermission,
                                      height: 50,
                                      fontSize: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
