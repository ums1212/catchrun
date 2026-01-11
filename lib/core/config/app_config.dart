import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  final String apiBaseUrl;
  final String environment;

  AppConfig({
    required this.apiBaseUrl,
    required this.environment,
  });

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    return AppConfig(
      apiBaseUrl: map['apiBaseUrl'] ?? '',
      environment: map['environment'] ?? 'prod',
    );
  }

  static AppConfig? _instance;

  static void init(Map<String, dynamic> config) {
    _instance = AppConfig.fromMap(config);
  }

  static AppConfig get instance {
    if (_instance == null) {
      throw Exception('AppConfig has not been initialized. Call init() first.');
    }
    return _instance!;
  }
}

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.instance);
