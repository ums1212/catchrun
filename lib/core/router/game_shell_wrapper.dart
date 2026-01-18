import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:catchrun/core/providers/app_bar_provider.dart';
import 'package:catchrun/core/widgets/hud_text.dart';
import 'package:catchrun/core/widgets/hud_dialog.dart';
import 'package:catchrun/core/widgets/scifi_button.dart';

class GameShellWrapper extends ConsumerWidget {
  final Widget child;

  const GameShellWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarConfig = ref.watch(appBarProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitDialog(context);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.black,
        appBar: appBarConfig.showAppBar 
            ? AppBar(
                title: HudText(
                  appBarConfig.title,
                  fontSize: 20,
                  letterSpacing: 2,
                  color: appBarConfig.titleColor ?? Colors.cyanAccent,
                ),
                centerTitle: appBarConfig.centerTitle,
                backgroundColor: appBarConfig.backgroundColor,
                elevation: appBarConfig.elevation,
                actions: appBarConfig.actions,
                bottom: appBarConfig.bottom,
                iconTheme: appBarConfig.iconTheme ?? const IconThemeData(color: Colors.cyanAccent),
                automaticallyImplyLeading: true,
                leading: context.canPop()
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => context.pop(),
                      )
                    : null,
              )
            : null,
        body: Stack(
          children: [
            // 1. Stable Background Image
            Positioned.fill(
              child: OrientationBuilder(
                builder: (context, orientation) {
                  final backgroundImage = orientation == Orientation.portrait
                      ? 'assets/image/profile_setting_portrait.png'
                      : 'assets/image/profile_setting_landscape.png';
                  
                  return Image.asset(
                    backgroundImage,
                    key: ValueKey(backgroundImage),
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            // 2. Persistent Dark Overlay & Gradient
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
            child,
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    HudDialog.show(
      context: context,
      title: '게임 종료',
      contentText: '정말 게임에서 나가시겠습니까?\n진행 중인 데이터는 무효화됩니다.',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: HudText(
            '취소',
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        SciFiButton(
          text: '나가기',
          height: 45,
          fontSize: 14,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            context.go('/home');
          },
        ),
      ],
    );
  }
}

