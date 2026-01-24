import 'package:catchrun/core/providers/app_bar_provider.dart';
import 'package:catchrun/core/widgets/hud_dialog.dart';
import 'package:catchrun/core/widgets/hud_text.dart';
import 'package:catchrun/core/widgets/scifi_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainShellWrapper extends ConsumerWidget {
  final Widget child;

  const MainShellWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarConfig = ref.watch(appBarProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final isHome = location == '/home';

    return PopScope(
      canPop: !isHome,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isHome) {
          _showExitDialog(context);
        }
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
                scrolledUnderElevation: 0, // 스크롤 시 색상 변화 방지
                actions: appBarConfig.actions,
                bottom: appBarConfig.bottom,
                iconTheme: appBarConfig.iconTheme ?? const IconThemeData(color: Colors.cyanAccent),
                automaticallyImplyLeading: true,
                leading: appBarConfig.leading ?? (context.canPop()
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => context.pop(),
                      )
                    : null),
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
                    key: ValueKey(backgroundImage), // 경로가 같으면 위젯 보존
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
      title: '종료 확인',
      contentText: '캐치런을 종료하시겠습니까?',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: HudText(
            '취소',
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        SciFiButton(
          text: '종료',
          height: 45,
          fontSize: 14,
          onPressed: () {
            SystemNavigator.pop();
          },
        ),
      ],
    );
  }
}
