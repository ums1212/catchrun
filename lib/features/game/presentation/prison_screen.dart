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

class PrisonScreen extends ConsumerStatefulWidget {
  final String gameId;

  const PrisonScreen({super.key, required this.gameId});

  @override
  ConsumerState<PrisonScreen> createState() => _PrisonScreenState();
}

class _PrisonScreenState extends ConsumerState<PrisonScreen> {
  bool _isScanning = false;

  Future<void> _useNfcKey() async {
    final availability = await NfcManager.instance.checkAvailability();
    
    if (availability != NfcAvailability.enabled) {
      if (!mounted) return;

      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'NfcDisabledDialog',
        pageBuilder: (context, _, __) => Center(
          child: GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HudText('NFC 비활성', fontSize: 18, color: Colors.redAccent),
                const SizedBox(height: 16),
                const HudText(
                  'NFC 기능이 꺼져 있거나 지원되지 않습니다.\n시스템 설정에서 활성화해 주세요.',
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                  color: Colors.white70,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SciFiButton(
                        text: '취소',
                        height: 45,
                        fontSize: 14,
                        isOutlined: true,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SciFiButton(
                        text: '설정',
                        height: 45,
                        fontSize: 14,
                        onPressed: () async {
                          await AppSettings.openAppSettings(type: AppSettingsType.nfc);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isScanning = true);
    if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'NfcScanDialog',
      pageBuilder: (context, _, __) => Center(
        child: GlassContainer(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.nfc, size: 64, color: Colors.orangeAccent),
              const SizedBox(height: 24),
              const HudText('열쇠 스캔 중', fontSize: 18, color: Colors.orangeAccent),
              const SizedBox(height: 16),
              const HudText(
                '등록된 NFC 열쇠를\n기기 뒷면에 인식시켜 주세요.',
                fontWeight: FontWeight.normal,
                fontSize: 12,
                color: Colors.white70,
              ),
              const SizedBox(height: 32),
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
          ),
        ),
      ),
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
        
        if (!mounted) return;
        Navigator.pop(context);
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('탈출 성공!'), backgroundColor: Colors.green),
        );

      } catch (e) {
        await NfcManager.instance.stopSession();
        if (!mounted) return;
        Navigator.pop(context);
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('탈출 실패: $e'), backgroundColor: Colors.red),
        );
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
                            const Spacer(),
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
                                    _buildStatItem('활동 요원', '${game.counts.robbersFree}', Colors.greenAccent),
                                    _buildStatItem('수감 인원', '${game.counts.robbersJailed}', Colors.redAccent),
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

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        HudText(label, fontSize: 10, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.normal),
        const SizedBox(height: 8),
        HudText(value, fontSize: 24, color: color),
      ],
    );
  }
}
