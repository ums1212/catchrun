import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:catchrun/core/models/game_model.dart';
import 'package:catchrun/core/models/participant_model.dart';
import 'package:catchrun/core/network/network_error_handler.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:catchrun/core/providers/app_bar_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:catchrun/features/game/presentation/widgets/event_popup_overlay.dart';
import 'package:catchrun/features/game/presentation/widgets/play_widgets.dart';
import '../../../../core/widgets/hud_text.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/scifi_button.dart';
import 'package:catchrun/core/widgets/stat_item.dart';
import 'package:catchrun/core/widgets/hud_dialog.dart';

class PlayScreen extends ConsumerStatefulWidget {
  final String gameId;
  const PlayScreen({super.key, required this.gameId});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  Duration _serverTimeOffset = Duration.zero;
  Map<String, dynamic>? _lastEvent;
  String? _lastEventId;
  bool _isProcessingAction = false;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _initServerTimeOffset();
    _startTimer();
    // AppBar 초기 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateAppBar(isCop: false); // 기본값, 이후 참가자 정보로 갱신
      }
    });
  }

  void _updateAppBar({required bool isCop}) {
    final themeColor = isCop ? Colors.blueAccent : Colors.redAccent;
    ref.read(appBarProvider.notifier).state = AppBarConfig(
      title: isCop ? 'MISSION: CATCH' : 'MISSION: RUN',
      centerTitle: true,
      titleColor: themeColor,
      actions: [
        IconButton(
          onPressed: () => _showExitDialog(context),
          icon: const Icon(Icons.close_rounded, color: Colors.white60),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initServerTimeOffset() async {
    try {
      final offset = await NetworkErrorHandler.wrap(() => ref.read(gameRepositoryProvider).calculateServerTimeOffset());
      if (mounted) {
        setState(() {
          _serverTimeOffset = offset;
        });
      }
    } catch (e) {
      // Ignore offset calculation error
    }
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
      
      // startedAt + durationSec을 사용해 종료 시간 계산 (서버 시간 기준)
      if (game.startedAt != null) {
        final estimatedServerTime = DateTime.now().add(_serverTimeOffset);
        final endsAt = game.startedAt!.add(Duration(seconds: game.durationSec));
        
        if (estimatedServerTime.isAfter(endsAt)) {
          // [Smart Jitter] 모든 클라이언트가 동시에 요청하는 것을 방지하기 위해 랜덤 지연 추가
          final randomDelay = (DateTime.now().millisecond % 3000); 
          Future.delayed(Duration(milliseconds: randomDelay), () {
            if (mounted) {
              NetworkErrorHandler.wrap(() => ref.read(gameRepositoryProvider).finishGame(
                game.id,
                serverTimeOffset: _serverTimeOffset,
              ));
            }
          });
        }
      }
      if (mounted) setState(() {});
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final gameStream = ref.watch(gameRepositoryProvider).watchGame(widget.gameId);
    final participantsStream = ref.watch(gameRepositoryProvider).watchParticipants(widget.gameId);
    final eventStream = ref.watch(gameRepositoryProvider).watchLatestEvent(widget.gameId);
    final currentUser = ref.watch(userProvider).value;

    return StreamBuilder<GameModel?>(
      stream: gameStream,
      builder: (context, gameSnapshot) {
        if (!gameSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
        }
        final game = gameSnapshot.data!;
        if (game.status == GameStatus.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/result/${widget.gameId}');
          });
          return const Center(child: HudText('게임이 종료되었습니다.', fontSize: 18));
        }

        return StreamBuilder<List<ParticipantModel>>(
          stream: participantsStream,
          builder: (context, partSnapshot) {
            final participants = partSnapshot.data ?? [];
            final myParticipant = participants.firstWhere(
              (p) => p.uid == currentUser?.uid,
              orElse: () => ParticipantModel(uid: '', nicknameSnapshot: '', joinedAt: DateTime.now(), stats: ParticipantStats()),
            );

            final isCop = myParticipant.role == ParticipantRole.cop;
            final isJailed = myParticipant.state == RobberState.jailed;
            final themeColor = isCop ? Colors.blueAccent : Colors.redAccent;

            if (!isCop && isJailed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  if (_isDialogOpen) {
                    Navigator.of(context, rootNavigator: true).pop();
                    _isDialogOpen = false;
                  }
                  context.go('/prison/${widget.gameId}');
                }
              });
              return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
            }

            // AppBar 설정 업데이트 (역할에 따라)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _updateAppBar(isCop: isCop);
            });

            // startedAt + durationSec을 사용해 종료 시간 계산 (서버 시간 기준)
            if (game.startedAt != null) {
              final estimatedServerTime = DateTime.now().add(_serverTimeOffset);
              final endsAt = game.startedAt!.add(Duration(seconds: game.durationSec));
              _remainingTime = endsAt.difference(estimatedServerTime);
              if (_remainingTime.isNegative) _remainingTime = Duration.zero;
            }

            return Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: kToolbarHeight),
                      const SizedBox(height: 20),
                      GlassContainer(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                        child: Column(
                          children: [
                            HudText('남은 시간', fontSize: 14, color: Colors.white.withValues(alpha: 0.6), letterSpacing: 2),
                            const SizedBox(height: 8),
                            HudText(_formatDuration(_remainingTime), fontSize: 64, color: themeColor, fontWeight: FontWeight.w900),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              StatItem(label: '전체', value: '${game.counts.robbers}', valueColor: Colors.white),
                              StatItem(label: '수감', value: '${game.counts.robbersJailed}', valueColor: Colors.redAccent),
                              StatItem(label: '활동', value: '${game.counts.robbersFree}', valueColor: Colors.greenAccent),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SciFiButton(
                          text: '활동 로그 확인',
                          height: 40,
                          fontSize: 12,
                          isOutlined: true,
                          onPressed: () => _showActivityLogDialog(context),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                if (!isCop) ...[
                                  Expanded(
                                    child: SciFiButton(
                                      text: '내 QR',
                                      isOutlined: true,
                                      height: 56,
                                      onPressed: () => _showMyQr(context, currentUser?.uid, themeColor),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                Expanded(
                                  child: SciFiButton(
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
                            GlassContainer(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              child: HudText(isCop ? '대상을 찾아 식별코드를 스캔하세요' : '추격을 피하고 수감된 동료를 도우세요', fontSize: 11, fontWeight: FontWeight.normal, color: themeColor.withValues(alpha: 0.8), letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                StreamBuilder<Map<String, dynamic>?>(
                  stream: eventStream,
                  builder: (context, eventSnapshot) {
                    final event = eventSnapshot.data;
                    if (event != null && event['id'] != _lastEventId) {
                      _lastEvent = event;
                      _lastEventId = event['id'];
                    }
                    return EventPopupOverlay(
                      event: _lastEvent,
                      onDismiss: () => setState(() => _lastEvent = null),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMyQr(BuildContext context, String? uid, Color themeColor) {
    if (uid == null) return;
    _isDialogOpen = true;
    HudDialog.show(
      context: context,
      title: '신원 식별 QR',
      titleColor: themeColor,
      content: MyQrDialogContent(gameId: widget.gameId, uid: uid),
      actions: [
        SciFiButton(
          text: '닫기',
          height: 45,
          fontSize: 14,
          onPressed: () {
            if (Navigator.of(context, rootNavigator: true).canPop()) {
              Navigator.of(context, rootNavigator: true).pop();
            }
            _isDialogOpen = false;
          },
        ),
      ],
    ).then((_) => _isDialogOpen = false);
  }

  void _showActivityLogDialog(BuildContext context) {
    _isDialogOpen = true;
    HudDialog.show(
      context: context,
      title: '활동 로그',
      content: ActivityLogDialogContent(gameId: widget.gameId),
      actions: [
        SciFiButton(
          text: '닫기',
          height: 45,
          fontSize: 14,
          onPressed: () {
            if (Navigator.of(context, rootNavigator: true).canPop()) {
              Navigator.of(context, rootNavigator: true).pop();
            }
            _isDialogOpen = false;
          },
        ),
      ],
    ).then((_) => _isDialogOpen = false);
  }

  void _showExitDialog(BuildContext context) {
    _isDialogOpen = true;
    HudDialog.show(
      context: context,
      title: '게임 종료',
      contentText: '정말 게임에서 나가시겠습니까?\n진행 중인 데이터는 무효화됩니다.',
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            _isDialogOpen = false;
          },
          child: const HudText('취소', color: Colors.white60),
        ),
        SciFiButton(
          text: '나가기',
          height: 45,
          fontSize: 14,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            _isDialogOpen = false;
            context.go('/home');
          },
        ),
      ],
    ).then((_) => _isDialogOpen = false);
  }
}
