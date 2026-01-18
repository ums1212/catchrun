import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 앱바의 상태를 정의하는 데이터 클래스
class AppBarConfig {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? titleColor;
  final PreferredSizeWidget? bottom;
  final bool showAppBar;
  final bool centerTitle;
  final Color? backgroundColor;
  final double? elevation;
  final IconThemeData? iconTheme;

  const AppBarConfig({
    required this.title,
    this.actions,
    this.leading,
    this.titleColor,
    this.bottom,
    this.showAppBar = true,
    this.centerTitle = true,
    this.backgroundColor = Colors.transparent,
    this.elevation = 0,
    this.iconTheme,
  });

  /// 기본 상태 (값이 없을 때 대비)
  static const defaultConfig = AppBarConfig(title: '');

  AppBarConfig copyWith({
    String? title,
    List<Widget>? actions,
    Widget? leading,
    Color? titleColor,
    PreferredSizeWidget? bottom,
    bool? showAppBar,
    bool? centerTitle,
    Color? backgroundColor,
    double? elevation,
    IconThemeData? iconTheme,
  }) {
    return AppBarConfig(
      title: title ?? this.title,
      actions: actions ?? this.actions,
      leading: leading ?? this.leading,
      titleColor: titleColor ?? this.titleColor,
      bottom: bottom ?? this.bottom,
      showAppBar: showAppBar ?? this.showAppBar,
      centerTitle: centerTitle ?? this.centerTitle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      elevation: elevation ?? this.elevation,
      iconTheme: iconTheme ?? this.iconTheme,
    );
  }
}

/// 현재 활성화된 화면의 앱바 설정을 관리하는 프로바이더
final appBarProvider = StateProvider<AppBarConfig>((ref) => AppBarConfig.defaultConfig);
