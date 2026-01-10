import 'dart:ui';
import 'package:catchrun/core/models/participant_model.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nfc_manager/nfc_manager.dart';
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
    
    final proceed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ExitDialog',
      pageBuilder: (context, _, __) => Center(
        child: _GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _HudText('게임 나가기', fontSize: 20, color: Colors.cyanAccent),
              const SizedBox(height: 16),
              const _HudText('대기방에서 나가시겠습니까?', fontWeight: FontWeight.normal),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: _HudText('취소', color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ),
                  Expanded(
                    child: _SciFiButton(
                      text: '나가기',
                      height: 45,
                      fontSize: 14,
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (proceed == true && mounted) {
      setState(() => _isExiting = true);
      await _leaveGameSilently();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _registerNfcKey(GameModel game) async {
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      if (mounted) {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'NfcDisabledDialog',
          pageBuilder: (context, _, __) => Center(
            child: _GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _HudText('NFC 기능 비활성화', fontSize: 18, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const _HudText(
                    'NFC 기능이 꺼져 있거나 지원되지 않는 기기입니다. 설정에서 NFC를 활성화해 주세요.',
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
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
                            await AppSettings.openAppSettings(type: AppSettingsType.nfc);
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
        );
      }
      return;
    }

    if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'NfcRegisterDialog',
      pageBuilder: (context, _, __) => Center(
        child: _GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _HudText('NFC 열쇠 등록', fontSize: 20, color: Colors.cyanAccent),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.nfc, size: 48, color: Colors.cyanAccent),
              ),
              const SizedBox(height: 24),
              const _HudText('빈 NFC 카드를 기기 뒷면에 접촉해 주세요.', fontWeight: FontWeight.normal),
              const SizedBox(height: 8),
              _HudText(
                '이 게임의 전용 열쇠 ID가 기록됩니다.',
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
                fontWeight: FontWeight.normal,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    NfcManager.instance.stopSession();
                    Navigator.pop(context);
                  },
                  child: _HudText('등록 취소', color: Colors.white.withValues(alpha: 0.6)),
                ),
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
              SnackBar(
                backgroundColor: Colors.cyanAccent.withValues(alpha: 0.8),
                content: const _HudText('NFC 열쇠 등록 성공!', color: Colors.black),
              ),
            );
          }
        } catch (e) {
          await NfcManager.instance.stopSession();
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.redAccent,
                content: _HudText('오류 발생: $e'),
              ),
            );
          }
        }
      }
    );
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
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
            );
          }

          final game = gameSnapshot.data;
          if (game == null) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: _HudText('게임을 찾을 수 없습니다.', color: Colors.redAccent)),
            );
          }

          if (game.status == GameStatus.playing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go('/play/${game.id}');
            });
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: _HudText('미션 시작!', fontSize: 24, color: Colors.cyanAccent)),
            );
          }

          if (game.status == GameStatus.finished) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isExiting) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.redAccent,
                    content: const _HudText('게임을 찾을 수 없거나 종료되었습니다.'),
                  ),
                );
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            });
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: _HudText('본부로 복귀 중...', fontSize: 18)),
            );
          }

          return Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.black,
            appBar: AppBar(
              title: const _HudText(
                '전투 대기실',
                fontSize: 20,
                letterSpacing: 2,
                color: Colors.cyanAccent,
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.cyanAccent),
              actions: [
                IconButton(
                  onPressed: () => _shareGame(game),
                  icon: const Icon(Icons.share_rounded, color: Colors.cyanAccent),
                ),
              ],
            ),
            body: OrientationBuilder(
              builder: (context, orientation) {
                final backgroundImage = orientation == Orientation.portrait
                    ? 'assets/image/profile_setting_portrait.png'
                    : 'assets/image/profile_setting_landscape.png';

                return SizedBox.expand(
                  child: Stack(
                    children: [
                      // Background Image
                      Positioned.fill(
                        child: Image.asset(backgroundImage, fit: BoxFit.cover),
                      ),
                      // Dark Overlay
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
                      // Main Content
                      SafeArea(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _GlassContainer(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    const _HudText('미션 식별 코드', fontSize: 12, color: Colors.white70),
                                    const SizedBox(height: 8),
                                    _HudText(
                                      game.gameCode,
                                      fontSize: 32,
                                      letterSpacing: 6,
                                      color: Colors.cyanAccent,
                                    ),
                                    const SizedBox(height: 8),
                                    _HudText(
                                      'SECRET KEY: ${game.inviteCode}',
                                      fontSize: 14,
                                      color: Colors.white54,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    if (game.joinQrEnabled) ...[
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withValues(alpha: 0.3),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: QrImageView(
                                          data: 'catchrun:${game.id}:${game.joinQrToken}',
                                          version: QrVersions.auto,
                                          size: 140.0,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: _HudSectionHeader(title: '참여 목록'),
                            ),
                            Expanded(
                              child: StreamBuilder(
                                stream: participantsAsync,
                                builder: (context, partSnapshot) {
                                  final participants = partSnapshot.data ?? [];
                                  final currentUser = ref.watch(userProvider).value;

                                  return ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: participants.length,
                                    itemBuilder: (context, index) {
                                      final p = participants[index];
                                      final isCurrentUser = p.uid == currentUser?.uid;
                                      final isHost = p.uid == game.hostUid;
                                      final isRoomHost = game.hostUid == currentUser?.uid;
                                      final isCop = p.role == ParticipantRole.cop;

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.4),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: (isCop ? Colors.blueAccent : Colors.redAccent)
                                                      .withValues(alpha: 0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: ListTile(
                                                onTap: isRoomHost ? () => _showRoleChangeBottomSheet(context, game, p) : null,
                                                leading: Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: isCop ? Colors.blueAccent : Colors.redAccent,
                                                      width: 1.5,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: (isCop ? Colors.blueAccent : Colors.redAccent)
                                                            .withValues(alpha: 0.3),
                                                        blurRadius: 8,
                                                      ),
                                                    ],
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    isCop ? '👮' : '🏃',
                                                    style: const TextStyle(fontSize: 20),
                                                  ),
                                                ),
                                                title: Row(
                                                  children: [
                                                    _HudText(p.nicknameSnapshot, fontSize: 16),
                                                    if (isCurrentUser) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.cyanAccent.withValues(alpha: 0.2),
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                                                        ),
                                                        child: const _HudText('YOU', fontSize: 10, color: Colors.cyanAccent),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                subtitle: _HudText(
                                                  isCop ? 'TACTICAL UNIT (POLICE)' : 'TARGET VESSEL (ROBBER)',
                                                  fontSize: 10,
                                                  color: isCop ? Colors.blueAccent : Colors.redAccent,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                                trailing: isHost 
                                                  ? const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 24)
                                                  : null,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            // Action Section
                            StreamBuilder(
                              stream: participantsAsync,
                              builder: (context, partSnapshot) {
                                final participants = partSnapshot.data ?? [];
                                final currentUser = ref.watch(userProvider).value;
                                final isHost = game.hostUid == currentUser?.uid;

                                return Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    children: [
                                      if (isHost) ...[
                                        _SciFiButton(
                                          text: '미션 개시',
                                          height: 54,
                                          fontSize: 18,
                                          onPressed: () async {
                                            final currentCops = participants.where((p) => p.role == ParticipantRole.cop).length;
                                            if (currentCops != game.rule.copsCount) {
                                              showGeneralDialog(
                                                context: context,
                                                barrierDismissible: true,
                                                barrierLabel: 'ConfigErrorDialog',
                                                pageBuilder: (context, _, __) => Center(
                                                  child: _GlassContainer(
                                                    padding: const EdgeInsets.all(24),
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const _HudText('인원 설정 불일치', fontSize: 18, color: Colors.orangeAccent),
                                                        const SizedBox(height: 16),
                                                        _HudText(
                                                          '설정된 경찰(${game.rule.copsCount}명)과 현재 배정된 인원($currentCops명)이 다릅니다.\n작전 조율이 필요합니다.',
                                                          fontWeight: FontWeight.normal,
                                                          fontSize: 14,
                                                        ),
                                                        const SizedBox(height: 24),
                                                        _SciFiButton(
                                                          text: '확인',
                                                          height: 45,
                                                          fontSize: 14,
                                                          onPressed: () => Navigator.pop(context),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                              return;
                                            }

                                            try {
                                              await ref.read(gameRepositoryProvider).startGame(game.id);
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    backgroundColor: Colors.redAccent,
                                                    content: _HudText('미션 개시 실패: $e'),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        GestureDetector(
                                          onTap: () => _registerNfcKey(game),
                                          child: Container(
                                            width: double.infinity,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                                              color: Colors.cyanAccent.withValues(alpha: 0.05),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.nfc_rounded, color: Colors.cyanAccent, size: 20),
                                                const SizedBox(width: 8),
                                                const _HudText('보안 열쇠(NFC) 등록', color: Colors.cyanAccent),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        _GlassContainer(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          child: const Center(
                                            child: _HudText(
                                              '작전 개시 대기 중...',
                                              color: Colors.cyanAccent,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
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
        },
      ),
    );
  }

  void _showRoleChangeBottomSheet(BuildContext context, GameModel game, ParticipantModel p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _HudText('${p.nicknameSnapshot} 역할 변경', fontSize: 18, color: Colors.cyanAccent),
                  const SizedBox(height: 8),
                  const _HudText('역할을 변경합니다.', fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white54),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent),
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                      ),
                      alignment: Alignment.center,
                      child: const Text('👮', style: TextStyle(fontSize: 20)),
                    ),
                    title: const _HudText('TACTICAL UNIT (경찰)'),
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
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent),
                        color: Colors.redAccent.withValues(alpha: 0.1),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🏃', style: TextStyle(fontSize: 20)),
                    ),
                    title: const _HudText('TARGET VESSEL (도둑)'),
                    onTap: () async {
                      await ref.read(gameRepositoryProvider).updateParticipantRole(
                        gameId: game.id,
                        uid: p.uid,
                        role: ParticipantRole.robber,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
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