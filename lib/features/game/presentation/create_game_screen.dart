import 'package:catchrun/core/models/game_model.dart';
import 'package:catchrun/features/auth/auth_controller.dart';
import 'package:catchrun/features/game/data/game_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catchrun/core/widgets/hud_text.dart';
import 'package:catchrun/core/widgets/glass_container.dart';
import 'package:catchrun/core/widgets/scifi_button.dart';
import 'package:catchrun/core/widgets/hud_section_header.dart';
import 'package:catchrun/core/widgets/hud_text_field.dart';
import 'package:catchrun/core/widgets/counter_button.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';

class CreateGameScreen extends ConsumerStatefulWidget {
  const CreateGameScreen({super.key});

  @override
  ConsumerState<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends ConsumerState<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  int _durationMinutes = 10;
  int _copsCount = 2;
  int _robbersCount = 6;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _createGame() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(userProvider).value;
      if (user == null) throw Exception('사용자 정보를 찾을 수 없습니다.');

      final gameId = await ref.read(gameRepositoryProvider).createGame(
            title: _titleController.text,
            durationSec: _durationMinutes * 60,
            rule: GameRule(
              copsCount: _copsCount,
              robbersCount: _robbersCount,
              useQr: true,
              useNfc: true,
              autoAssignRoles: true,
            ),
            host: user,
          );

      if (!mounted) return;

      context.go('/lobby/$gameId');

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: HudText('게임 생성 중 오류 발생: $e', color: Colors.white),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNumberPicker({
    required String title,
    required int initialValue,
    required ValueChanged<int> onSelected,
    required Color color,
  }) {
    int selectedValue = initialValue;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  HudText(title, color: color, fontSize: 18),
                  TextButton(
                    onPressed: () {
                      onSelected(selectedValue);
                      Navigator.pop(context);
                    },
                    child: const HudText('확인', color: Colors.cyanAccent),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoTheme(
                data: const CupertinoThemeData(
                  textTheme: CupertinoTextThemeData(
                    pickerTextStyle: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: initialValue - 1,
                  ),
                  onSelectedItemChanged: (index) {
                    selectedValue = index + 1;
                  },
                  children: List.generate(
                    99,
                    (index) => Center(
                      child: HudText(
                        '${index + 1}',
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const HudText(
          '게임 만들기',
          fontSize: 20,
          letterSpacing: 2,
          color: Colors.cyanAccent,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final backgroundImage = orientation == Orientation.portrait
              ? 'assets/image/profile_setting_portrait.png'
              : 'assets/image/profile_setting_landscape.png';

          return SizedBox.expand(
            child: Stack(
              children: [
                // 1. Background Image
                Positioned.fill(
                  child: Image.asset(
                    backgroundImage,
                    fit: BoxFit.cover,
                  ),
                ),
                // 2. Dark Overlay & Gradient
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
                // 3. Content
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          HudSectionHeader(title: '게임 설정'),
                          const SizedBox(height: 20),
                          // Game Name Input
                          HudTextField(
                            controller: _titleController,
                            labelText: '게임 이름',
                            hintText: '우리동네 한판!',
                            validator: (value) => 
                                (value == null || value.isEmpty) ? '게임 이름을 입력해주세요.' : null,
                          ),
                          const SizedBox(height: 32),
                          // Duration Slider
                          GlassContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const HudText('제한 시간', fontSize: 16),
                                    HudText('$_durationMinutes분', color: Colors.cyanAccent, fontSize: 18),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.cyanAccent,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Colors.white,
                                    overlayColor: Colors.cyanAccent.withValues(alpha: 0.2),
                                    valueIndicatorColor: Colors.cyanAccent,
                                    valueIndicatorTextStyle: const TextStyle(color: Colors.black),
                                  ),
                                  child: Slider(
                                    value: _durationMinutes.toDouble(),
                                    min: 5,
                                    max: 60,
                                    divisions: 11,
                                    label: '$_durationMinutes분',
                                    onChanged: (val) => setState(() => _durationMinutes = val.toInt()),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Participants Setup
                          GlassContainer(
                            child: Row(
                              children: [
                                Expanded(
                                  child: ParticipantCounter(
                                    label: '경찰 인원',
                                    count: _copsCount,
                                    color: Colors.blueAccent,
                                    onIncrement: () => setState(() => _copsCount++),
                                    onDecrement: _copsCount > 1 
                                        ? () => setState(() => _copsCount--) 
                                        : null,
                                    onCountPressed: () => _showNumberPicker(
                                      title: '경찰 인원 선택',
                                      initialValue: _copsCount,
                                      color: Colors.blueAccent,
                                      onSelected: (val) => setState(() => _copsCount = val),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60,
                                  color: Colors.white10,
                                ),
                                Expanded(
                                  child: ParticipantCounter(
                                    label: '도둑 인원',
                                    count: _robbersCount,
                                    color: Colors.redAccent,
                                    onIncrement: () => setState(() => _robbersCount++),
                                    onDecrement: _robbersCount > 1 
                                        ? () => setState(() => _robbersCount--) 
                                        : null,
                                    onCountPressed: () => _showNumberPicker(
                                      title: '도둑 인원 선택',
                                      initialValue: _robbersCount,
                                      color: Colors.redAccent,
                                      onSelected: (val) => setState(() => _robbersCount = val),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 60),
                          // Action Button
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                          else
                            SciFiButton(
                              text: '게임 생성 및 대기방 입장',
                              icon: Icons.rocket_launch_rounded,
                              onPressed: _createGame,
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
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
