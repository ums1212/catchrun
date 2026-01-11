import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:app_settings/app_settings.dart';
import 'package:catchrun/core/models/game_model.dart';
import 'package:catchrun/core/models/participant_model.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:catchrun/core/widgets/hud_text.dart';
import 'package:catchrun/core/widgets/glass_container.dart';
import 'package:catchrun/core/widgets/scifi_button.dart';
import 'package:catchrun/core/widgets/stat_item.dart';
import 'package:catchrun/core/widgets/hud_dialog.dart';

class PrisonScreen extends ConsumerStatefulWidget {
  final String gameId;

  const PrisonScreen({super.key, required this.gameId});

  @override
  ConsumerState<PrisonScreen> createState() => _PrisonScreenState();
}

class _PrisonScreenState extends ConsumerState<PrisonScreen> {
  bool _isScanning = false;
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  Duration _serverTimeOffset = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initServerTimeOffset();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initServerTimeOffset() async {
    try {
      final offset = await ref.read(gameRepositoryProvider).calculateServerTimeOffset();
      if (mounted) {
        setState(() {
          _serverTimeOffset = offset;
        });
      }
    } catch (e) {
      // offset 계산 실패 시 기본값(Duration.zero) 유지
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {});
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _useNfcKey() async {
    final availability = await NfcManager.instance.checkAvailability();
    
    if (availability != NfcAvailability.enabled) {
      if (!mounted) return;

      HudDialog.show(
        context: context,
        title: 'NFC 비활성',
        titleColor: Colors.redAccent,
        contentText: 'NFC 기능이 꺼져 있거나 지원되지 않습니다.\n시스템 설정에서 활성화해 주세요.',
        actions: [
          SciFiButton(
            text: '취소',
            height: 45,
            fontSize: 14,
            isOutlined: true,
            onPressed: () {
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          ),
          SciFiButton(
            text: '설정',
            height: 45,
            fontSize: 14,
            onPressed: () async {
              final navigator = Navigator.of(context);
              await AppSettings.openAppSettings(type: AppSettingsType.nfc);
              if (mounted) navigator.pop();
            },
          ),
        ],
      );
      return;
    }

    setState(() => _isScanning = true);
    if (!mounted) return;

    HudDialog.show(
      context: context,
      barrierDismissible: false,
      title: '열쇠 스캔 중',
      titleColor: Colors.orangeAccent,
      content: Column(
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.nfc, size: 64, color: Colors.orangeAccent),
          const SizedBox(height: 24),
          const HudText(
            '등록된 NFC 열쇠를\n기기 뒷면에 인식시켜 주세요.',
            fontWeight: FontWeight.normal,
            fontSize: 12,
            color: Colors.white70,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        SciFiButton(
          text: '중단',
          height: 45,
          fontSize: 14,
          isOutlined: true,
          onPressed: () {
            NfcManager.instance.stopSession();
            Navigator.pop(context);
            setState(() => _isScanning = false);
          },
        ),
      ],
    );

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      onDiscovered: (NfcTag tag) async {
      try {
        final ndef = Ndef.from(tag);
        if (ndef == null || ndef.cachedMessage == null) {
          throw Exception('유효한 열쇠 데이터가 없습니다.');
        }

        final record = ndef.cachedMessage!.records.first;
        final languageCodeLength = record.payload[0];
        final scannedId = String.fromCharCodes(record.payload.sublist(1 + languageCodeLength));

        final currentUser = ref.read(userProvider).value;
        if (currentUser == null) throw Exception('User authentication lost.');

        await ref.read(gameRepositoryProvider).usePrisonKey(
          gameId: widget.gameId,
          uid: currentUser.uid,
          scannedId: scannedId,
        );

        await NfcManager.instance.stopSession();
        
        if (mounted) {
          Navigator.pop(context);
          setState(() => _isScanning = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('탈출 성공!'), backgroundColor: Colors.green),
          );
        }

      } catch (e) {
        await NfcManager.instance.stopSession();
        if (mounted) {
          Navigator.pop(context);
          setState(() => _isScanning = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('탈출 실패: $e'), backgroundColor: Colors.red),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider).value;
    final gameAsync = ref.watch(gameRepositoryProvider).watchGame(widget.gameId);
    
    return StreamBuilder<GameModel?>(
      stream: gameAsync,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.redAccent)),
          );
        }

        final game = snapshot.data!;
        
        // 게임 종료 시 결과 화면으로 이동
        if (game.status == GameStatus.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/result/${widget.gameId}');
            }
          });
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: HudText('게임이 종료되었습니다.', fontSize: 18)),
          );
        }
        
        // 서버 시간 기준으로 남은 시간 계산
        if (game.endsAt != null) {
          final estimatedServerTime = DateTime.now().add(_serverTimeOffset);
          _remainingTime = game.endsAt!.difference(estimatedServerTime);
          if (_remainingTime.isNegative) _remainingTime = Duration.zero;
        }
        
        final participantsAsync = ref.watch(gameRepositoryProvider).watchParticipants(widget.gameId);
        
        return StreamBuilder<List<ParticipantModel>>(
          stream: participantsAsync,
          builder: (context, partSnapshot) {
            final participants = partSnapshot.data ?? [];
            final myParticipant = participants.firstWhere(
              (p) => p.uid == currentUser?.uid,
              orElse: () => ParticipantModel(uid: '', nicknameSnapshot: '', joinedAt: DateTime.now(), stats: ParticipantStats()),
            );

            if (myParticipant.state == RobberState.free && myParticipant.uid.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted && !_isScanning) {
                  context.go('/play/${widget.gameId}');
                }
              });
            }

            final qrData = 'catchrun:${game.id}:${currentUser?.uid}';

            return Scaffold(
              backgroundColor: Colors.black,
              body: OrientationBuilder(
                builder: (context, orientation) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          orientation == Orientation.portrait
                              ? 'assets/image/profile_setting_portrait.png'
                              : 'assets/image/profile_setting_landscape.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.85),
                                Colors.redAccent.withValues(alpha: 0.1),
                                Colors.black.withValues(alpha: 0.9),
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
                            GlassContainer(
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                              child: Column(
                                children: [
                                  HudText(
                                    '남은 시간', 
                                    fontSize: 14, 
                                    color: Colors.white.withValues(alpha: 0.6),
                                    letterSpacing: 2,
                                  ),
                                  const SizedBox(height: 8),
                                  HudText(
                                    _formatDuration(_remainingTime),
                                    fontSize: 48,
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Icon(
                              Icons.lock_person_rounded,
                              size: 100,
                              color: Colors.redAccent,
                              shadows: [
                                Shadow(color: Colors.redAccent, blurRadius: 20),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const HudText(
                              '수감 상태 활성',
                              fontSize: 32,
                              color: Colors.redAccent,
                              letterSpacing: 2,
                            ),
                            const SizedBox(height: 16),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 48),
                              child: HudText(
                                '지정된 장소에서 대기하세요.\n동료가 당신의 ID를 스캔하면 석방됩니다.',
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                                color: Colors.white70,
                                letterSpacing: 1,
                              ),
                            ),
                            const Spacer(),
                            
                            GlassContainer(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: QrImageView(
                                      data: qrData,
                                      version: QrVersions.auto,
                                      size: 200.0,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const HudText(
                                    '신원 식별 코드',
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 48),
                              child: SciFiButton(
                                text: 'NFC 마스터키 사용',
                                icon: Icons.vpn_key_rounded,
                                onPressed: _useNfcKey,
                              ),
                            ),
                            
                            const Spacer(),
                            
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                              child: GlassContainer(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    StatItem(label: '활동 요원', value: '${game.counts.robbersFree}', valueColor: Colors.greenAccent),
                                    StatItem(label: '수감 인원', value: '${game.counts.robbersJailed}', valueColor: Colors.redAccent),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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

}
