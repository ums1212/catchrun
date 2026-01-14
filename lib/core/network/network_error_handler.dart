import 'package:catchrun/core/network/network_exceptions.dart';
import 'package:catchrun/core/router/app_router.dart';
import 'package:catchrun/core/widgets/network_error_dialog.dart';

class NetworkErrorHandler {
  static void handle(Object error) {
    if (error is NoNetworkException) {
      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        NetworkErrorDialog.show(context);
      }
    }
  }

  static Future<T> wrap<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      handle(e);
      rethrow;
    }
  }
}
