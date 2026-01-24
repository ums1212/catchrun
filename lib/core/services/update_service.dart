import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// 앱 업데이트를 관리하는 서비스 클래스
class UpdateService {
  UpdateService._internal();
  static final UpdateService instance = UpdateService._internal();

  /// 업데이트 상태를 확인하고 필요한 경우 즉시 업데이트를 실행합니다.
  Future<void> checkForUpdate() async {
    // 안드로이드가 아닌 경우 무시
    if (!Platform.isAndroid) return;

    try {
      debugPrint('Checking for updates...');
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        debugPrint('Update available: ${info.availableVersionCode}');
        
        // 즉시 업데이트가 가능한지 확인
        if (info.immediateUpdateAllowed) {
          debugPrint('Starting immediate update...');
          try {
            final result = await InAppUpdate.performImmediateUpdate();
            if (result == AppUpdateResult.success) {
              debugPrint('Update successful');
            } else if (result == AppUpdateResult.userDeniedUpdate) {
              debugPrint('User denied update');
              // 즉시 업데이트의 경우 사용자가 거부하면 앱을 종료하거나 
              // 다시 업데이트를 유도하는 로직이 필요할 수 있습니다.
            }
          } catch (e) {
            debugPrint('Error during immediate update: $e');
          }
        } else {
          debugPrint('Immediate update not allowed');
        }
      } else {
        debugPrint('No update available');
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
    }
  }
}
