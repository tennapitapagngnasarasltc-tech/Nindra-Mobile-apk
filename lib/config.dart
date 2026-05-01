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
  static const String deployedBaseUrl = 'https://backend-t3db.onrender.com';

  static String get apiBaseUrl {
    // Allow quickly switching between local dev and deployed backend.
    if (useDeployedBackend) {
      return deployedBaseUrl;
    }
    if (kIsWeb) {
      // Web platform - try network IP first, fallback to localhost
      return 'http://$networkIp:$port';
    } else {
      // Mobile platforms - use conditional import for Platform
      return _getMobileApiUrl();
    }
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
  static const String supabaseAnonKey ='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV4d3l1dnFwYWdka2l0eGtydHF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxMTY5MDgsImV4cCI6MjA5MjY5MjkwOH0.LgLTLyLjPe77tKKmW9_OJnQMa27YVgkrbKmTK9BwzE8';
}