import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // Helper to safely get env values
  static String _getEnv(String key, String defaultValue) {
    try {
      return dotenv.env[key] ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }
  
  // Environment - default to 'production' for release builds
  static String get environment => _getEnv('ENVIRONMENT', 'production');
  static bool get isTest => environment == 'test';
  static bool get isProduction => environment == 'production';

  // Config Helpers
  static bool get useMockData => isTest;
  static bool get useFirebase => isProduction;

  // App Configuration
  static String get appName => _getEnv('APP_NAME', 'Battle of Couples');
  static String get appVersion => _getEnv('APP_VERSION', '1.0.0');

  // API Configuration
  static String get apiBaseUrl => _getEnv('API_BASE_URL', 'https://api.example.com');
  static int get apiTimeout => int.tryParse(_getEnv('API_TIMEOUT', '30000')) ?? 30000;

  // Unsplash API (Test Mode Only)
  static String get unsplashAccessKey => _getEnv('UNSPLASH_ACCESS_KEY', '');
  static String get unsplashSecretKey => _getEnv('UNSPLASH_SECRET_KEY', '');
  static bool get hasUnsplashKeys => unsplashAccessKey.isNotEmpty && unsplashSecretKey.isNotEmpty;
}
