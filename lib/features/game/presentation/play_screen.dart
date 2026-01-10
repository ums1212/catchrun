import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:catchrun/core/models/game_model.dart';
import 'package:catchrun/core/models/participant_model.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:catchrun/features/game/presentation/widgets/event_popup_overlay.dart';

class PlayScreen extends ConsumerStatefulWidget {
  final String gameId;
  const PlayScreen({super.key, required this.gameId});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  Map<String, dynamic>? _lastEvent;
  String? _lastEventId;
  bool _isProcessingAction = false; // 디바운스용

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _checkEndConditions();
    });
  }

  void _checkEndConditions() {
    final gameAsync = ref.read(gameRepositoryProvider).watchGame(widget.gameId);
    gameAsync.first.then((game) {
      if (game == null || game.status != GameStatus.playing) return;

      final currentUser = ref.read(userProvider).value;
      if (game.hostUid != currentUser?.uid) return;

      // 1. 시간 종료 체크
      if (game.endsAt != null && DateTime.now().isAfter(game.endsAt!)) {
        ref.read(gameRepositoryProvider).finishGame(game.id);
        return;
      }
    });
    
    setState(() {});
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(gameRepositoryProvider).watchGame(widget.gameId);
    final participantsAsync = ref.watch(gameRepositoryProvider).watchParticipants(widget.gameId);
    final eventAsync = ref.watch(gameRepositoryProvider).watchLatestEvent(widget.gameId);
    final currentUser = ref.watch(userProvider).value;

    return StreamBuilder<GameModel?>(
      stream: gameAsync,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
          );
        }

        final game = snapshot.data!;
        
        if (game.status == GameStatus.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/result/${widget.gameId}');
            }
          });
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: _HudText('게임이 종료되었습니다.', fontSize: 18)),
          );
        }

        return StreamBuilder<List<ParticipantModel>>(
          stream: participantsAsync,
          builder: (context, partSnapshot) {
            final participants = partSnapshot.data ?? [];
            final myParticipant = participants.firstWhere(
              (p) => p.uid == currentUser?.uid,
              orElse: () => ParticipantModel(uid: '', nicknameSnapshot: '', joinedAt: DateTime.now(), stats: ParticipantStats()),
            );

            final isCop = myParticipant.role == ParticipantRole.cop;
            final isJailed = myParticipant.state == RobberState.jailed;
            
            if (!isCop && isJailed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.go('/prison/${widget.gameId}');
                }
              });
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(child: CircularProgressIndicator(color: Colors.redAccent)),
              );
            }

            final themeColor = isCop ? Colors.blueAccent : Colors.redAccent;

            if (game.endsAt != null) {
              _remainingTime = game.endsAt!.difference(DateTime.now());
              if (_remainingTime.isNegative) _remainingTime = Duration.zero;
            }

            return Scaffold(
              backgroundColor: Colors.black,
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: _HudText(
                  isCop ? '미션: 추격' : '미션: 생존',
                  color: themeColor,
                  fontSize: 18,
                ),
                centerTitle: true,
                automaticallyImplyLeading: false,
              ),
              body: OrientationBuilder(
                builder: (context, orientation) {
                  return Stack(
                    children: [
                      // Background Image
                      Positioned.fill(
                        child: Image.asset(
                          orientation == Orientation.portrait
                              ? 'assets/image/profile_setting_portrait.png'
                              : 'assets/image/profile_setting_landscape.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Gradient Overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.black.withValues(alpha: 0.3),
                                Colors.black.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      SafeArea(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            // Timer Section
                            _GlassContainer(
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                              child: Column(
                                children: [
                                  _HudText(
                                    '남은 시간', 
                                    fontSize: 14, 
                                    color: Colors.white.withValues(alpha: 0.6),
                                    letterSpacing: 2,
                                  ),
                                  const SizedBox(height: 8),
                                  _HudText(
                                    _formatDuration(_remainingTime),
                                    fontSize: 64,
                                    color: themeColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Status Board
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _GlassContainer(
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem('전체', '${game.counts.robbers}', Colors.white),
                                    _buildStatItem('수감', '${game.counts.robbersJailed}', Colors.redAccent),
                                    _buildStatItem('활동', '${game.counts.robbersFree}', Colors.greenAccent),
                                  ],
                                ),
                              ),
                            ),
                            
                            const Spacer(),
                            
                            // Action Buttons
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      if (!isCop) ...[
                                        Expanded(
                                          child: _SciFiButton(
                                            text: '내 QR',
                                            isOutlined: true,
                                            height: 56,
                                            onPressed: () => _showMyQr(context, currentUser?.uid, themeColor),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                      ],
                                      Expanded(
                                        child: _SciFiButton(
                                          text: isCop ? '대상 스캔' : '팀원 구출',
                                          height: 56,
                                          onPressed: _isProcessingAction ? () {} : () async {
                                            setState(() => _isProcessingAction = true);
                                            context.push('/qr-scan/${widget.gameId}?isCop=$isCop');
                                            await Future.delayed(const Duration(seconds: 2));
                                            if (mounted) setState(() => _isProcessingAction = false);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  // Guidance
                                  _GlassContainer(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                    child: _HudText(
                                      isCop 
                                        ? '대상을 찾아 식별코드를 스캔하세요' 
                                        : '추격을 피하고 수감된 동료를 도우세요',
                                      fontSize: 11,
                                      fontWeight: FontWeight.normal,
                                      color: themeColor.withValues(alpha: 0.8),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                      
                      // Event Popup Overlay
                      StreamBuilder<Map<String, dynamic>?>(
                        stream: eventAsync,
                        builder: (context, eventSnapshot) {
                          final event = eventSnapshot.data;
                          if (event != null && event['id'] != _lastEventId) {
                            _lastEvent = event;
                            _lastEventId = event['id'];
                          }
                          
                          return EventPopupOverlay(
                            event: _lastEvent,
                            onDismiss: () {
                              setState(() {
                                _lastEvent = null;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        _HudText(label, fontSize: 10, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.normal),
        const SizedBox(height: 6),
        _HudText(value, fontSize: 24, color: color),
      ],
    );
  }

  void _showMyQr(BuildContext context, String? uid, Color themeColor) {
    if (uid == null) return;
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'MyQrDialog',
      pageBuilder: (context, _, __) => Center(
        child: _GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HudText('신원 식별 QR', fontSize: 18, color: themeColor),
              const SizedBox(height: 16),
              const _HudText(
                '구출을 위해 아군에게 보여주거나\n식별을 위해 경찰에게 보여주세요.', 
                fontWeight: FontWeight.normal,
                fontSize: 12,
                color: Colors.white70,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: 'catchrun:${widget.gameId}:$uid',
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 24),
              _SciFiButton(
                text: '닫기',
                height: 45,
                fontSize: 14,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// HUD WIDGETS
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
      textAlign: TextAlign.center,
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

class _SciFiButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isOutlined;
  final double height;
  final double fontSize;

  const _SciFiButton({
    required this.text,
    required this.onPressed,
    this.icon,
    this.isOutlined = false,
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
          gradient: isOutlined
              ? null
              : const LinearGradient(
                  colors: [Colors.blueAccent, Colors.redAccent],
                ),
          color: isOutlined ? Colors.black.withValues(alpha: 0.4) : null,
          border: isOutlined
              ? _GradientBorder(
                  width: 1.5,
                  gradient: const LinearGradient(
                    colors: [Colors.blueAccent, Colors.redAccent],
                  ),
                )
              : null,
          boxShadow: isOutlined
              ? []
              : [
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!isOutlined)
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
