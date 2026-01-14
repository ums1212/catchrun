import 'package:catchrun/core/widgets/hud_dialog.dart';
import 'package:catchrun/core/widgets/scifi_button.dart';
import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';

class NetworkErrorDialog {
  static Future<void> show(BuildContext context) async {
    return HudDialog.show(
      context: context,
      title: '인터넷 연결 끊김',
      titleColor: Colors.redAccent,
      contentText: '인터넷 연결이 끊켰습니다. 네트워크 설정을 확인해주세요.',
      barrierDismissible: false,
      actions: [
        SciFiButton(
          text: '취소',
          onPressed: () => Navigator.of(context).pop(),
          isOutlined: true,
        ),
        const SizedBox(width: 12),
        SciFiButton(
          text: '설정',
          onPressed: () {
            AppSettings.openAppSettings(type: AppSettingsType.wifi);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
