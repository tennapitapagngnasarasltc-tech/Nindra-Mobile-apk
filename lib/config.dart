import 'package:flutter/foundation.dart';

class Config {
  // Network IP for local network access
  static const String networkIp = '192.168.1.6';
  static const String port = '8000';
  // Use the deployed backend on Render (or other host)
  // Toggle this during build using --dart-define=USE_DEPLOYED_BACKEND=true
  static const bool useDeployedBackend = bool.fromEnvironment(
    'USE_DEPLOYED_BACKEND',
    defaultValue: false,
  );
  static const String deployedBaseUrl = 'https://backend-o5fa.onrender.com';

  // Runtime fallback flag (set automatically when local backend unreachable)
  static bool _useRenderFallback = false;

  static void enableRenderFallback() => _useRenderFallback = true;
  static bool get isUsingRenderFallback => _useRenderFallback;

  static const String apiUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (apiUrlOverride.isNotEmpty) return apiUrlOverride;
    if (useDeployedBackend || _useRenderFallback) return deployedBaseUrl;

    if (kIsWeb) return 'http://localhost:$port';
    return _getMobileLocalhostUrl();
  }

  // Alternative localhost URL for development
  static String get localhostApiUrl {
    if (kIsWeb) {
      return 'http://localhost:$port';
    } else {
      return _getMobileLocalhostUrl();
    }
  }

  static String _getMobileApiUrl() {
    // Use defaultTargetPlatform instead of Platform for better cross-platform support
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android device - use network IP
        return 'http://$networkIp:$port';
      case TargetPlatform.iOS:
        // iOS simulator/device - use network IP
        return 'http://$networkIp:$port';
      default:
        // Desktop or other platforms
        return 'http://$networkIp:$port';
    }
  }

  static String _getMobileLocalhostUrl() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator needs special localhost address
        return 'http://10.0.2.2:$port';
      case TargetPlatform.iOS:
        // iOS simulator can use localhost
        return 'http://localhost:$port';
      default:
        // Desktop or other platforms
        return 'http://localhost:$port';
    }
  }

  static const String supabaseUrl = 'https://uxwyuvqpagdkitxkrtqy.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV4d3l1dnFwYWdka2l0eGtydHF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxMTY5MDgsImV4cCI6MjA5MjY5MjkwOH0.LgLTLyLjPe77tKKmW9_OJnQMa27YVgkrbKmTK9BwzE8';
}