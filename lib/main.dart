import 'package:catchrun/core/config/app_config.dart';
import 'package:catchrun/core/router/app_router.dart';
import 'package:catchrun/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:catchrun/core/services/update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Initialize Firebase safely with .env options
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized (likely by Flutter): $e');
    } else {
      rethrow;
    }
  }

  // Enable Edge-to-Edge mode and set transparent system bars
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize AppConfig using .env values via flutter_dotenv
  AppConfig.init({
    'apiBaseUrl': dotenv.env['API_BASE_URL'] ?? '',
    'environment': dotenv.env['ENVIRONMENT'] ?? 'development',
  });

  // Check for Android In-App Update
  // Non-blocking call to not delay app startup, but InAppUpdate will show its own UI
  UpdateService.instance.checkForUpdate();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Catch Run',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // 다크 모드 고정 (프로젝트 성격상)
      routerConfig: router,
      builder: (context, child) {
        return Container(
          color: Colors.black,
          child: child,
        );
      },
    );
  }
}
