import 'package:catchrun/core/models/participant_model.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ndef_record/ndef_record.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:app_settings/app_settings.dart';
import 'dart:typed_data';
import 'dart:convert';

import '../../../core/models/game_model.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final String gameId;
  const LobbyScreen({super.key, required this.gameId});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  late final AppLifecycleListener _lifecycleListener;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onDetach: _leaveGameSilently,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _leaveGameSilently() async {
    final currentUser = ref.read(userProvider).value;
    if (currentUser != null) {
      await ref.read(gameRepositoryProvider).leaveGame(
            gameId: widget.gameId,
            uid: currentUser.uid,
          );
    }
  }

  Future<void> _shareGame(GameModel game) async {
    final String message = '캐치런 게임에 초대합니다! 🏃‍♂️\n\n'
        '🎮 게임 이름: ${game.title}\n'
        '🔢 게임 번호: ${game.gameCode}\n'
        '🔑 초대 코드: ${game.inviteCode}\n\n'
        '앱을 실행하고 코드 입력 또는 QR 스캔으로 참가하세요!';
    
    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: '${game.title} 게임 초대',
      ),
    );
  }

  Future<void> _handleExit() async {
    if (_isExiting) return;
    
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게임 나가기'),
        content: const Text('대기방에서 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );

    if (proceed == true && mounted) {
      setState(() => _isExiting = true);
      await _leaveGameSilently();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _registerNfcKey(GameModel game) async {
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

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('NFC 열쇠 등록'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.nfc, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text('빈 NFC 카드를 기기 뒷면에 접촉해 주세요.'),
            SizedBox(height: 8),
            Text('이 게임의 전용 열쇠 ID가 기록됩니다.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              NfcManager.instance.stopSession();
              Navigator.pop(context);
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
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            throw Exception('기록할 수 없는 태그입니다.');
          }

          final message = NdefMessage(records: [
            _createNdefTextRecord(game.keyItem.nfcKeyId),
          ]);

          await ndef.write(message: message);
          await NfcManager.instance.stopSession();
        
        if (mounted) {
          Navigator.pop(context); // 다이얼로그 닫기
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('NFC 열쇠 등록 성공!')),
          );
        }
      } catch (e) {
        await NfcManager.instance.stopSession();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류 발생: $e')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(gameRepositoryProvider).watchGame(widget.gameId);
    final participantsAsync = ref.watch(gameRepositoryProvider).watchParticipants(widget.gameId);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _handleExit();
      },
      child: StreamBuilder(
        stream: gameAsync,
        builder: (context, gameSnapshot) {
          if (gameSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final game = gameSnapshot.data;
          if (game == null) {
            return const Scaffold(body: Center(child: Text('게임을 찾을 수 없습니다.')));
          }

          if (game.status == GameStatus.playing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go('/play/${game.id}');
            });
            return const Scaffold(body: Center(child: Text('게임이 시작되었습니다!')));
          }

          if (game.status == GameStatus.finished) {
            // 게임이 삭제되었거나 방장이 나가서 종료된 경우
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isExiting) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('게임을 찾을 수 없거나 종료되었습니다.')),
                );
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            });
            return const Scaffold(body: Center(child: Text('게임을 종료합니다...')));
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(game.title),
              actions: [
                IconButton(
                  onPressed: () => _shareGame(game),
                  icon: const Icon(Icons.share),
                ),
              ],
            ),
            body: SafeArea(
              bottom: true,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('게임 참여 코드'),
                            Text(
                              game.gameCode,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('초대 코드: ${game.inviteCode}'),
                            const SizedBox(height: 16),
                            if (game.joinQrEnabled)
                              QrImageView(
                                data: 'catchrun:${game.id}:${game.joinQrToken}',
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.white,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: StreamBuilder(
                      stream: participantsAsync,
                      builder: (context, partSnapshot) {
                        final participants = partSnapshot.data ?? [];
                        final currentUser = ref.watch(userProvider).value;
  
                        return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              '참여 인원: ${participants.length}명',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: participants.length,
                              itemBuilder: (context, index) {
                                final p = participants[index];
                                final isCurrentUser = p.uid == currentUser?.uid;
                                final isHost = p.uid == game.hostUid;
                                final isRoomHost = game.hostUid == currentUser?.uid;

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: p.role == ParticipantRole.cop 
                                        ? Colors.blue[100] 
                                        : Colors.red[100],
                                    child: Text(
                                      p.role == ParticipantRole.cop ? '👮' : '🏃',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(p.nicknameSnapshot),
                                    ],
                                  ),
                                  subtitle: Text(
                                    p.role == ParticipantRole.cop ? '경찰' : '도둑',
                                    style: TextStyle(
                                      color: p.role == ParticipantRole.cop ? Colors.blue : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  onTap: isRoomHost ? () => _showRoleChangeBottomSheet(context, game, p) : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isCurrentUser) const Chip(label: Text('나')),
                                      if (isHost) const Icon(Icons.star, color: Colors.amber),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: game.hostUid == currentUser?.uid
                                ? FilledButton(
                                    onPressed: () async {
                                      final currentCops = participants.where((p) => p.role == ParticipantRole.cop).length;
                                      if (currentCops != game.rule.copsCount) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('인원 설정 오류'),
                                            content: Text('설정된 경찰 인원(${game.rule.copsCount}명)과 현재 배정된 경찰 수($currentCops명)가 일치하지 않습니다.\n현장에서 역할을 조율해주세요.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('확인'),
                                              ),
                                            ],
                                          ),
                                        );
                                        return;
                                      }

                                      try {
                                        await ref.read(gameRepositoryProvider).startGame(game.id);
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('게임 시작 실패: $e')),
                                          );
                                        }
                                      }
                                    },
                                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                                    child: const Text('게임 시작'),
                                  )
                                : const Center(child: Text('방장이 게임을 시작하기를 기다리는 중...')),
                          ),
                          if (game.hostUid == currentUser?.uid)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: OutlinedButton.icon(
                                onPressed: () => _registerNfcKey(game),
                                icon: const Icon(Icons.nfc),
                                label: const Text('NFC 열쇠 등록 (NDEF 쓰기)'),
                                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRoleChangeBottomSheet(BuildContext context, GameModel game, ParticipantModel p) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('${p.nicknameSnapshot} 역할 설정'),
                subtitle: const Text('방장 권한으로 역할을 강제 배정합니다.'),
              ),
              const Divider(),
              ListTile(
                leading: const Text('👮', style: TextStyle(fontSize: 24)),
                title: const Text('경찰로 변경'),
                onTap: () async {
                  await ref.read(gameRepositoryProvider).updateParticipantRole(
                    gameId: game.id,
                    uid: p.uid,
                    role: ParticipantRole.cop,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🏃', style: TextStyle(fontSize: 24)),
                title: const Text('도둑으로 변경'),
                onTap: () async {
                  await ref.read(gameRepositoryProvider).updateParticipantRole(
                    gameId: game.id,
                    uid: p.uid,
                    role: ParticipantRole.robber,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  NdefRecord _createNdefTextRecord(String text) {
    const languageCode = 'en';
    final payload = Uint8List.fromList([
      languageCode.length,
      ...utf8.encode(languageCode),
      ...utf8.encode(text),
    ]);
    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList(utf8.encode('T')),
      identifier: Uint8List(0),
      payload: payload,
    );
  }
}
