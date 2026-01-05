import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ndef_record/ndef_record.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:app_settings/app_settings.dart';
import 'package:catchrun/core/models/game_model.dart';
import 'package:catchrun/core/models/participant_model.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';

class PrisonScreen extends ConsumerStatefulWidget {
  final String gameId;

  const PrisonScreen({super.key, required this.gameId});

  @override
  ConsumerState<PrisonScreen> createState() => _PrisonScreenState();
}

class _PrisonScreenState extends ConsumerState<PrisonScreen> {
  bool _isScanning = false;

  Future<void> _useNfcKey() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('NFC 기능 비활성화'),
            content: const Text('NFC 기능이 꺼져 있거나 지원되지 않는 기기입니다. 설정에서 NFC를 활성화해 주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () async {
                  await AppSettings.openAppSettings(type: AppSettingsType.nfc);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('설정으로 이동'),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() => _isScanning = true);
    
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('NFC 열쇠 사용'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.nfc, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text('등록된 NFC 열쇠를 기기 뒷면에 접촉해 주세요.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              NfcManager.instance.stopSession();
              Navigator.pop(context);
              setState(() => _isScanning = false);
            },
            child: const Text('취소'),
          ),
        ],
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
        if (currentUser == null) throw Exception('사용자 정보를 찾을 수 없습니다.');

        await ref.read(gameRepositoryProvider).usePrisonKey(
          gameId: widget.gameId,
          uid: currentUser.uid,
          scannedId: scannedId,
        );

        await NfcManager.instance.stopSession();
        
        if (context.mounted) {
          Navigator.pop(context); // 다이얼로그 닫기
          setState(() => _isScanning = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('탈출 성공!')),
          );
        }
      } catch (e) {
        await NfcManager.instance.stopSession();
        if (context.mounted) {
          Navigator.pop(context);
          setState(() => _isScanning = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('탈출 실패: $e')),
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

            // 석방 감지 시 다시 플레이 화면으로
            if (myParticipant.state == RobberState.free && myParticipant.uid.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted && !_isScanning) {
                  context.go('/play/${widget.gameId}');
                }
              });
            }

            final qrData = 'catchrun:${game.id}:${currentUser?.uid}';

            return Scaffold(
          backgroundColor: Colors.grey[900],
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Icon(
                  Icons.lock_person,
                  size: 80,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 24),
                const Text(
                  '현재 수감되었습니다!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    '지정된 감옥 위치에 머물러야 하며, 이동이 불가합니다. 동료가 QR 코드를 스캔해주면 석방될 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
                const Spacer(),
                
                // 내 QR 코드
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 240.0,
                    gapless: false,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '내 구출용 QR 코드',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // NFC 열쇠 사용 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: ElevatedButton.icon(
                    onPressed: _useNfcKey,
                    icon: const Icon(Icons.vpn_key),
                    label: const Text('NFC 열쇠로 직접 탈출'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // 게임 정보 요약
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('남은 도둑', '${game.counts.robbersFree}', Colors.greenAccent),
                      _buildStatItem('수감 인원', '${game.counts.robbersJailed}', Colors.redAccent),
                    ],
                  ),
                ),
              ],
            ),
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
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
