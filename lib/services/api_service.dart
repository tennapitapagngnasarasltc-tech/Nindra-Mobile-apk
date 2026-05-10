import 'dart:convert';
import 'package:nindra/config.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// ──────────────────────────────────────────────
// MODELS
// ──────────────────────────────────────────────
class SleepInput {
  final String gender;
  final int age;
  final String occupation;
  final double sleepDuration;
  final int physicalActivityLevel;
  final int stressLevel;
  final String bmiCategory;
  final int systolic;
  final int diastolic;
  final int? sleepQuality;
  final double? deepSleepPct;
  final double? remSleepPct;
  final double? sleepPercent;
  final String? userId;

  SleepInput({
    required this.gender,
    required this.age,
    required this.occupation,
    required this.sleepDuration,
    required this.physicalActivityLevel,
    required this.stressLevel,
    required this.bmiCategory,
    required this.systolic,
    required this.diastolic,
    this.sleepQuality,
    this.deepSleepPct,
    this.remSleepPct,
    this.sleepPercent,
    this.userId,
  });

  Map<String, dynamic> toJson() => {
    'gender': gender,
    'age': age,
    'occupation': occupation,
    'sleep_duration': sleepDuration,
    'physical_activity_level': physicalActivityLevel,
    'stress_level': stressLevel,
    'bmi_category': bmiCategory,
    'systolic': systolic,
    'diastolic': diastolic,
    if (sleepQuality != null) 'sleep_quality': sleepQuality,
    if (deepSleepPct != null) 'deep_sleep_pct': deepSleepPct,
    if (remSleepPct != null) 'rem_sleep_pct': remSleepPct,
    if (sleepPercent != null) 'sleep_percent': sleepPercent,
    if (userId != null) 'user_id': userId,
  };
}

class SleepPredictionResponse {
  final String userId;
  final String email;
  final double sleepScore;
  final String scoreBand;
  final int? sleepQuality;
  final double? deepSleepPct;
  final double? remSleepPct;
  final double? sleepPercent;
  final String overall;
  final List<String> priorityFixes;
  final List<String> strategies;
  final List<String> warnings;
  final List<String> positives;

  SleepPredictionResponse({
    required this.userId,
    required this.email,
    required this.sleepScore,
    required this.scoreBand,
    this.sleepQuality,
    this.deepSleepPct,
    this.remSleepPct,
    this.sleepPercent,
    required this.overall,
    required this.priorityFixes,
    required this.strategies,
    required this.warnings,
    required this.positives,
  });

  factory SleepPredictionResponse.fromJson(Map<String, dynamic> json) =>
      SleepPredictionResponse(
        userId: json['user_id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        sleepScore: (json['sleep_score'] as num?)?.toDouble() ?? 0.0,
        scoreBand: json['score_band'] as String? ?? '',
        sleepQuality: (json['sleep_quality'] as num?)?.toInt(),
        deepSleepPct: (json['deep_sleep_pct'] as num?)?.toDouble(),
        remSleepPct: (json['rem_sleep_pct'] as num?)?.toDouble(),
        sleepPercent: (json['sleep_percent'] as num?)?.toDouble(),
        overall: json['overall'] as String? ?? '',
        priorityFixes: List<String>.from(json['priority_fixes'] as List? ?? []),
        strategies: List<String>.from(json['strategies'] as List? ?? []),
        warnings: List<String>.from(json['warnings'] as List? ?? []),
        positives: List<String>.from(json['positives'] as List? ?? []),
      );
}

// ──────────────────────────────────────────────
// API SERVICE
// ──────────────────────────────────────────────
class ApiService {
  static String get baseUrl => Config.apiBaseUrl;

  /// Get auth token from Supabase session
  static Future<String?> getAuthToken() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      print('❌ No active Supabase session');
      return null;
    }
    return session.accessToken;
  }

  /// Get standard headers with auth token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getAuthToken();
    if (token == null) {
      throw Exception('Authentication required. Please log in.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Predict sleep quality based on user profile
  /// Returns [SleepPredictionResponse] with predictions and recommendations
  static Future<SleepPredictionResponse?> predictSleep(SleepInput input) async {
    try {
      print('📤 Sending sleep prediction request...');
      print('   Endpoint: $baseUrl/predict');

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: headers,
        body: jsonEncode(input.toJson()),
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final prediction = SleepPredictionResponse.fromJson(jsonData);
        print('✅ Sleep prediction successful');
        print('   Score: ${prediction.sleepScore} (${prediction.scoreBand})');
        return prediction;
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized: Please log in again');
        return null;
      } else {
        print('❌ Error: ${response.statusCode}');
        print('   Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Failed to predict sleep: $e');
      return null;
    }
  }

  /// Get saved user profile and latest prediction from backend
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      print('📤 Fetching user profile...');
      print('   Endpoint: $baseUrl/profile');

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final profile = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ Profile fetched successfully');
        return profile;
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized: Please log in again');
        return null;
      } else {
        print('❌ Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Failed to get profile: $e');
      return null;
    }
  }

  /// Legacy method for background AI execution.
  ///
  /// This method is intentionally disabled because /predict requires valid user data.
  @deprecated
  static Future<void> runAI() async {
    print(
      '⚠️  runAI() is deprecated and no longer supported. Use predictSleep() with valid input data instead.',
    );
  }
}
