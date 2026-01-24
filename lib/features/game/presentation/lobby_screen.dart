import 'package:catchrun/core/network/network_error_handler.dart';
import 'package:catchrun/core/widgets/hud_dialog.dart';
import 'package:catchrun/features/game/presentation/widgets/lobby_game_code_card.dart';
import 'package:catchrun/features/game/presentation/widgets/lobby_participant_tile.dart';
import 'dart:ui';
import 'package:catchrun/core/models/participant_model.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catchrun/core/providers/app_bar_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:app_settings/app_settings.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:catchrun/core/widgets/hud_text.dart';
import 'package:catchrun/core/widgets/glass_container.dart';
import 'package:catchrun/core/widgets/scifi_button.dart';
import 'package:catchrun/core/widgets/hud_section_header.dart';
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
  StreamSubscription? _participantsSubscription;
  
  // 스크롤 컨트롤러 (카드에서 스크롤 감지용으로 사용)
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onDetach: _leaveGameSilently,
    );
    _setupKickDetection();
    
    // Deep Link 참여 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateAppBar();
        _handleDeepLinkJoin();
      }
    });

    // 프로필 로딩 완료 후 다시 시도하기 위해 리스너 추가
    ref.listenManual(userProvider, (previous, next) {
      if (next.hasValue && next.value != null && mounted) {
        _handleDeepLinkJoin();
      }
    });
  }

  bool _deepLinkHandled = false;

  void _handleDeepLinkJoin() async {
    if (_deepLinkHandled) return;
    
    final state = GoRouterState.of(context);
    final nfcKeyId = state.uri.queryParameters['nfcKeyId'];
    
    if (nfcKeyId != null) {
      // nfcKeyId가 있는 경우, 이미 참여 중인지 확인 후 자동 참여 시도
      final currentUser = ref.read(userProvider).value;
      if (currentUser == null) return;
      
      _deepLinkHandled = true;

      final gameRepo = ref.read(gameRepositoryProvider);
      final participants = await gameRepo.watchParticipants(widget.gameId).first;
      final isAlreadyIn = participants.any((p) => p.uid == currentUser.uid);

      if (!isAlreadyIn && mounted) {
        // 초대 코드를 알 수 없으므로, NFC 열쇠 기반의 특수한 참여 API가 필요할 수 있음.
        // 현재는 repository에 joinByNfcKey 같은 메소드가 없으므로, 
        // nfcKeyId가 맞는지 확인 후 joinGameByQr과 유사하게 처리하거나 
        // repository에 기능을 추가해야 합니다.
        // 일단은 안내 메시지 및 참여 시도 로직 스켈레톤 작성.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: HudText('보안 열쇠로 입장 시도 중...'))
        );
        
        try {
          // repository에 joinGameByNfcKey(gameId, nfcKeyId, user) 추가 필요
          await NetworkErrorHandler.wrap(() => gameRepo.joinGameByNfcKey(
            gameId: widget.gameId,
            nfcKeyId: nfcKeyId,
            user: currentUser,
          ));
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(backgroundColor: Colors.redAccent, content: HudText('입장 실패: $e'))
            );
          }
        }
      }
    }
  }

  void _updateAppBar() {
    ref.read(appBarProvider.notifier).state = AppBarConfig(
      title: '대기실',
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => _handleExit(),
      ),
    );
  }

  void _updateAppBarWithGame(GameModel game) {
    ref.read(appBarProvider.notifier).state = AppBarConfig(
      title: '대기실',
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => _handleExit(),
      ),
      actions: [
        IconButton(
          onPressed: () => _shareGame(game),
          icon: const Icon(Icons.share_rounded, color: Colors.cyanAccent, size: 20),
        ),
      ],
    );
  }

  void _setupKickDetection() {
    final participantsStream = ref.read(gameRepositoryProvider).watchParticipants(widget.gameId);
    bool hasSeenSelf = false;

    _participantsSubscription = participantsStream.listen((participants) {
      final currentUser = ref.read(userProvider).value;
      if (currentUser != null && !_isExiting) {
        final isInGame = participants.any((p) => p.uid == currentUser.uid);
        if (isInGame) {
          hasSeenSelf = true;
        } else if (hasSeenSelf) {
          _isExiting = true;
          if (mounted) {
            context.go('/home?kicked=true');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _participantsSubscription?.cancel();
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _leaveGameSilently() async {
    final currentUser = ref.read(userProvider).value;
    if (currentUser != null) {
      await NetworkErrorHandler.wrap(() => ref.read(gameRepositoryProvider).leaveGame(
            gameId: widget.gameId,
            uid: currentUser.uid,
          ));
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
    if (!mounted) return;
    
    final navigator = Navigator.of(context, rootNavigator: true);
    
    final proceed = await HudDialog.show<bool>(
      context: context,
      title: '게임 나가기',
      contentText: '대기방에서 나가시겠습니까?',
      actions: [
        TextButton(
          onPressed: () => navigator.pop(false),
          child: HudText('취소', color: Colors.white.withValues(alpha: 0.6)),
        ),
        SciFiButton(
          text: '나가기',
          height: 45,
          fontSize: 14,
          onPressed: () => navigator.pop(true),
        ),
      ],
    );

    if (proceed == true && mounted) {
      setState(() => _isExiting = true);
      await _leaveGameSilently();
      if (mounted) context.go('/home');
    }
  }

  Future<void> _registerNfcKey(GameModel game) async {
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      if (mounted) {
        HudDialog.show(
          context: context,
          title: 'NFC 기능 비활성화',
          titleColor: Colors.redAccent,
          contentText: 'NFC 기능이 꺼져 있거나 지원되지 않는 기기입니다. 설정에서 NFC를 활성화해 주세요.',
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: HudText('취소', color: Colors.white.withValues(alpha: 0.6)),
            ),
            SciFiButton(
              text: '설정 이동',
              height: 45,
              fontSize: 14,
              onPressed: () async {
                final navigator = Navigator.of(context, rootNavigator: true);
                await AppSettings.openAppSettings(type: AppSettingsType.nfc);
                if (mounted) navigator.pop();
              },
            ),
          ],
        );
      }
      return;
    }

    if (!mounted) return;
    HudDialog.show(
      context: context,
      barrierDismissible: false,
      title: 'NFC 열쇠 등록',
      content: Column(
        children: [
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
          const HudText('빈 NFC 카드를 기기 뒷면에 접촉해 주세요.', fontWeight: FontWeight.normal),
          const SizedBox(height: 8),
          HudText(
            '이 게임의 전용 열쇠 ID가 기록됩니다.',
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.normal,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            NfcManager.instance.stopSession();
            Navigator.of(context, rootNavigator: true).pop();
          },
          child: HudText('등록 취소', color: Colors.white.withValues(alpha: 0.6)),
        ),
      ],
    );

    if (!context.mounted) return;
    final navigatorState = Navigator.of(context, rootNavigator: true);
    final messengerState = ScaffoldMessenger.of(context);

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            throw Exception('기록할 수 없는 태그입니다.');
          }

          final uri = 'https://catchrun.app/join?gameId=${game.id}&nfcKeyId=${game.keyItem.nfcKeyId}';
          final message = NdefMessage(records: [
            NdefRecord(
              typeNameFormat: TypeNameFormat.wellKnown,
              type: Uint8List.fromList(utf8.encode('U')),
              identifier: Uint8List(0),
              payload: Uint8List.fromList([
                0x04, // https://
                ...utf8.encode(uri.replaceFirst('https://', '')),
              ]),
            ),
            NdefRecord(
              typeNameFormat: TypeNameFormat.external,
              type: Uint8List.fromList(utf8.encode('android.com:pkg')),
              identifier: Uint8List(0),
              payload: Uint8List.fromList(utf8.encode('dev.comon.catchrun')),
            ),
          ]);

          await ndef.write(message: message);
          await NfcManager.instance.stopSession();
        
          if (mounted) {
            navigatorState.pop();
            messengerState.showSnackBar(
              SnackBar(
                backgroundColor: Colors.cyanAccent.withValues(alpha: 0.8),
                content: const HudText('NFC 열쇠 등록 성공!', color: Colors.black),
              ),
            );
          }
        } catch (e) {
          await NfcManager.instance.stopSession();
          if (mounted) {
            navigatorState.pop();
            messengerState.showSnackBar(
              SnackBar(
                backgroundColor: Colors.redAccent,
                content: HudText('오류 발생: $e'),
              ),
            );
          }
        }
      }
    );
  }

  void _toggleCard() {
    if (!_scrollController.hasClients) return;
    
    const double expandedHeight = 400.0;
    const double collapsedHeight = 84.0;
    const double threshold = (expandedHeight - collapsedHeight) / 2;
    
    if (_scrollController.offset > threshold) {
      // 펼치기
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 접기
      _scrollController.animateTo(
        expandedHeight - collapsedHeight,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
      child: StreamBuilder<GameModel?>(
        stream: gameAsync,
        builder: (context, gameSnapshot) {
          if (gameSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          }

          final game = gameSnapshot.data;
          if (game == null) {
            return const Center(child: HudText('게임을 찾을 수 없습니다.', color: Colors.redAccent));
          }

          if (game.status == GameStatus.playing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go('/play/${game.id}');
            });
            return const Center(child: HudText('미션 시작!', fontSize: 24, color: Colors.cyanAccent));
          }

          if (game.status == GameStatus.finished) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isExiting) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.redAccent,
                    content: HudText('게임을 찾을 수 없거나 종료되었습니다.'),
                  ),
                );
                context.go('/home');
              }
            });
            return const Center(child: HudText('본부로 복귀 중...', fontSize: 18));
          }

          // AppBar에 share 액션 추가 (game 로드 후)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _updateAppBarWithGame(game);
          });

          return StreamBuilder<List<ParticipantModel>>(
            stream: participantsAsync,
            builder: (context, partSnapshot) {
              final participants = partSnapshot.data ?? [];
              final currentUser = ref.watch(userProvider).value;
              final isHost = game.hostUid == currentUser?.uid;

              return SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: NestedScrollView(
                        controller: _scrollController,
                        headerSliverBuilder: (context, innerBoxIsScrolled) {
                          return [
                            SliverOverlapAbsorber(
                              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                              sliver: SliverPersistentHeader(
                                pinned: true,
                                delegate: LobbyGameCodeHeaderDelegate(
                                  game: game,
                                  expandedHeight: 350,
                                  collapsedHeight: 44,
                                  onToggle: _toggleCard,
                                ),
                              ),
                            ),
                          ];
                        },
                        body: Builder(
                          builder: (context) {
                            return CustomScrollView(
                              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                              slivers: [
                                SliverOverlapInjector(
                                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                                ),
                                const SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                                    child: HudSectionHeader(title: '참여 목록'),
                                  ),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final p = participants[index];
                                        final isCurrentUser = p.uid == currentUser?.uid;
                                        final isHostIdx = p.uid == game.hostUid;
                                        final isRoomHost = game.hostUid == currentUser?.uid;

                                        return LobbyParticipantTile(
                                          participant: p,
                                          isCurrentUser: isCurrentUser,
                                          isHost: isHostIdx,
                                          isRoomHost: isRoomHost,
                                          onTap: isRoomHost
                                              ? () {
                                                  if (isCurrentUser) {
                                                    _showRoleChangeBottomSheet(context, game, p);
                                                  } else {
                                                    _showParticipantActionBottomSheet(context, game, p);
                                                  }
                                                }
                                              : null,
                                        );
                                      },
                                      childCount: participants.length,
                                    ),
                                  ),
                                ),
                                if (participants.isEmpty && partSnapshot.connectionState != ConnectionState.waiting)
                                  const SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.all(40),
                                      child: Center(
                                        child: HudText('참여 중인 요원이 없습니다.', color: Colors.white38),
                                      ),
                                    ),
                                  ),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 100),
                                ),
                              ],
                            );
                          }
                        ),
                      ),
                    ),
                    // 고정 하단 액션 섹션
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isHost) ...[
                            SciFiButton(
                              text: '미션 개시',
                              height: 54,
                              fontSize: 18,
                              onPressed: () async {
                                final currentCops = participants.where((p) => p.role == ParticipantRole.cop).length;
                                if (currentCops != game.rule.copsCount) {
                                  HudDialog.show(
                                    context: context,
                                    title: '인원 설정 불일치',
                                    titleColor: Colors.orangeAccent,
                                    contentText: '설정된 경찰(${game.rule.copsCount}명)과 현재 배정된 인원($currentCops명)이 다릅니다.\n작전 조율이 필요합니다.',
                                    actions: [
                                      SciFiButton(
                                        text: '확인',
                                        height: 45,
                                        fontSize: 14,
                                        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                                      ),
                                    ],
                                  );
                                  return;
                                }

                                try {
                                  await NetworkErrorHandler.wrap(() => ref.read(gameRepositoryProvider).startGame(game.id));
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.redAccent,
                                        content: HudText('미션 개시 실패: $e'),
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
                                    SizedBox(width: 8),
                                    HudText('보안 열쇠(NFC) 등록', color: Colors.cyanAccent),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            GlassContainer(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: const Center(
                                child: HudText(
                                  '작전 개시 대기 중...',
                                  color: Colors.cyanAccent,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showParticipantActionBottomSheet(BuildContext context, GameModel game, ParticipantModel p) {

    Widget sheetContent = Container(
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
            HudText('${p.nicknameSnapshot} 관리', fontSize: 18, color: Colors.cyanAccent),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.person_pin_rounded, color: Colors.cyanAccent),
              title: const HudText('역할 설정'),
              onTap: () {
                Navigator.pop(context);
                _showRoleChangeBottomSheet(context, game, p);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_rounded, color: Colors.redAccent),
              title: const HudText('강퇴하기', color: Colors.redAccent),
              onTap: () {
                Navigator.pop(context);
                _showKickConfirmationDialog(context, game, p);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: sheetContent,
        );
      },
    );
  }

  void _showKickConfirmationDialog(BuildContext context, GameModel game, ParticipantModel p) {
    HudDialog.show(
      context: context,
      title: '강퇴 확인',
      titleColor: Colors.redAccent,
      contentText: '${p.nicknameSnapshot}님을 강퇴하시겠습니까?',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: HudText('취소', color: Colors.white.withValues(alpha: 0.6)),
        ),
        SciFiButton(
          text: '강퇴',
          height: 45,
          fontSize: 14,
          onPressed: () async {
            final navigator = Navigator.of(context, rootNavigator: true);
            await NetworkErrorHandler.wrap(() => ref.read(gameRepositoryProvider).kickParticipant(
              gameId: game.id,
              uid: p.uid,
            ));
            navigator.pop();
          },
        ),
      ],
    );
  }

  void _showRoleChangeBottomSheet(BuildContext context, GameModel game, ParticipantModel p) {

    Widget sheetContent = Container(
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
            HudText('${p.nicknameSnapshot} 역할 변경', fontSize: 18, color: Colors.cyanAccent),
            const SizedBox(height: 8),
            const HudText('역할을 변경합니다.', fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white54),
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
              title: const HudText('TACTICAL UNIT (경찰)'),
              onTap: () async {
                await NetworkErrorHandler.wrap(() => ref.read(gameRepositoryProvider).updateParticipantRole(
                  gameId: game.id,
                  uid: p.uid,
                  role: ParticipantRole.cop,
                ));
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
              title: const HudText('TARGET VESSEL (도둑)'),
              onTap: () async {
                await NetworkErrorHandler.wrap(() => ref.read(gameRepositoryProvider).updateParticipantRole(
                  gameId: game.id,
                  uid: p.uid,
                  role: ParticipantRole.robber,
                ));
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: sheetContent,
        );
      },
    );
  }

}
