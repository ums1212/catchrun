import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_config/flutter_config.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static final FirebaseOptions android = FirebaseOptions(
    apiKey: FlutterConfig.get('ANDROID_FIREBASE_API_KEY'),
    appId: '1:1094815367424:android:07415bd9c10938dbbab3e5',
    messagingSenderId: '1094815367424',
    projectId: 'catch-run',
    storageBucket: 'catch-run.firebasestorage.app',
  );

  static final FirebaseOptions ios = FirebaseOptions(
    apiKey: FlutterConfig.get('IOS_FIREBASE_API_KEY'),
    appId: '1:1094815367424:ios:afd4a7decccf8911bab3e5',
    messagingSenderId: '1094815367424',
    projectId: 'catch-run',
    storageBucket: 'catch-run.firebasestorage.app',
    iosClientId: '1094815367424-3g5vcb0igdrbgtr8j3ipsi047cdp91ni.apps.googleusercontent.com',
    iosBundleId: 'dev.comon.catchrun',
  );
}
