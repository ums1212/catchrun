import 'dart:ui';
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'PermissionDismiss',
      pageBuilder: (context, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: _GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _HudText('카메라 권한 필요', fontSize: 20, color: Colors.cyanAccent),
                const SizedBox(height: 16),
                const _HudText(
                  'QR 코드 스캔을 위해 카메라 권한이 필요합니다. 설정 화면에서 권한을 허용해주세요.',
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: _HudText('취소', color: Colors.white.withValues(alpha: 0.6)),
                      ),
                    ),
                    Expanded(
                      child: _SciFiButton(
                        text: '설정 이동',
                        height: 45,
                        fontSize: 14,
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          await openAppSettings();
                          if (mounted) navigator.pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
              SnackBar(
                backgroundColor: Colors.redAccent,
                content: const _HudText('유효하지 않은 QR 코드 형식입니다.'),
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
          content: _HudText('참가 중 오류 발생: $e'),
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
        title: const _HudText(
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
                              _HudSectionHeader(title: '게임 코드 정보'),
                              const SizedBox(height: 24),
                              _HudTextField(
                                controller: _gameCodeController,
                                labelText: '게임 번호 (9자리)',
                                hintText: '예: 123456789',
                                keyboardType: TextInputType.number,
                                validator: (value) => 
                                    (value?.length != 9) ? '9자리 번호를 입력해주세요.' : null,
                              ),
                              const SizedBox(height: 20),
                              _HudTextField(
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
                                _SciFiButton(
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
                            _QrScanOverlay(),
                          if (_isPermissionDenied && !_isScanning)
                            Center(
                              child: _GlassContainer(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.cyanAccent),
                                    const SizedBox(height: 24),
                                    const _HudText('카메라 권한이 거부되었습니다.', fontSize: 16),
                                    const SizedBox(height: 32),
                                    _SciFiButton(
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

class _QrScanOverlay extends StatelessWidget {
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
              border: _GradientBorder(
                width: 3,
                gradient: const LinearGradient(
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
            child: _HudText(
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

// REUSING HUD WIDGETS
class _HudText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final double letterSpacing;
  final FontWeight fontWeight;

  const _HudText(
    this.text, {
    this.fontSize = 14,
    this.color = Colors.white,
    this.letterSpacing = 1.0,
    this.fontWeight = FontWeight.bold,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        shadows: [
          Shadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

class _HudSectionHeader extends StatelessWidget {
  final String title;

  const _HudSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.cyanAccent,
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.6),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _HudText(
          title,
          fontSize: 12,
          color: Colors.cyanAccent.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyanAccent.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
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

class _HudTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _HudTextField({
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HudText(labelText, fontSize: 12, color: Colors.white70),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: const _GradientBorder(
                  width: 1.5,
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.redAccent],
                  ),
                ),
              ),
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                style: const TextStyle(color: Colors.white, letterSpacing: 1.2),
                validator: validator,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  border: InputBorder.none,
                  hintText: hintText,
                  hintStyle: const TextStyle(color: Colors.white24),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SciFiButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final double height;
  final double fontSize;

  const _SciFiButton({
    required this.text,
    required this.onPressed,
    this.icon,
    this.height = 60,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Colors.redAccent],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(-5, 0),
            ),
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(5, 0),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 2,
              left: 10,
              right: 10,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: fontSize + 4),
                  const SizedBox(width: 12),
                ],
                _HudText(
                  text,
                  fontSize: fontSize,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ],
            ),
          ],
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
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
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
  ShapeBorder scale(double t) => _GradientBorder(gradient: gradient, width: width * t);

  @override
  BorderSide get bottom => BorderSide.none;
  @override
  BorderSide get top => BorderSide.none;
}
