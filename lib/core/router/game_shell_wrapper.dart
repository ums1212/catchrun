import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:catchrun/core/providers/app_bar_provider.dart';
import 'package:catchrun/core/widgets/hud_text.dart';

class GameShellWrapper extends ConsumerWidget {
  final Widget child;

  const GameShellWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarConfig = ref.watch(appBarProvider);

    return Scaffold(
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
          // PlayScreen과 동일한 어두운 배경 유지 (일관성)
          Positioned.fill(
            child: Container(color: Colors.black),
          ),
          child,
        ],
      ),
    );
  }
}
