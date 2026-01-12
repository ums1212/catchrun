import 'package:flutter/material.dart';
import 'package:catchrun/core/widgets/glass_container.dart';
import 'package:catchrun/core/widgets/hud_text.dart';

class HudDialog extends StatelessWidget {
  final String title;
  final Color titleColor;
  final String? contentText;
  final Widget? content;
  final List<Widget> actions;

  const HudDialog({
    super.key,
    required this.title,
    this.titleColor = Colors.cyanAccent,
    this.contentText,
    this.content,
    required this.actions,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    Color titleColor = Colors.cyanAccent,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
    String? contentText,
    Widget? content,
    required List<Widget> actions,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'HudDialog',
      useRootNavigator: useRootNavigator,
      pageBuilder: (context, _, __) => Center(
        child: HudDialog(
          title: title,
          titleColor: titleColor,
          contentText: contentText,
          content: content,
          actions: actions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HudText(title, fontSize: 20, color: titleColor),
          const SizedBox(height: 16),
          if (contentText != null)
            HudText(
              contentText!,
              fontWeight: FontWeight.normal,
              textAlign: TextAlign.center,
            ),
          if (content != null) content!,
          const SizedBox(height: 32),
          Row(
            children: actions.map((action) => Expanded(child: action)).toList(),
          ),
        ],
      ),
    );
  }
}
