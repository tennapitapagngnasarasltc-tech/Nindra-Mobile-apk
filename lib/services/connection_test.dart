import 'package:http/http.dart' as http;
import 'package:nindra/config.dart';
import 'package:nindra/services/api_service.dart';

class ConnectionTest {
  /// Run full connection diagnostic test
  static Future<void> runFullTest() async {
    print('\n' + '=' * 60);
    print('🔍 FRONTEND-BACKEND CONNECTION TEST');
    print('=' * 60 + '\n');

    // Test 1: Backend reachable
    print('1️⃣  Testing backend health...');
    try {
      final response = await http
          .get(Uri.parse('${ApiService.baseUrl}/'))
          .timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        print('   ✅ Backend reachable at: ${ApiService.baseUrl}');
        print('   Response: ${response.body}');
      } else {
        print('   ⚠️  Backend returned status: ${response.statusCode}');
        print('   Response: ${response.body}');
      }
    } catch (e) {
      print('   ❌ Local backend unreachable');
      print('   Error: $e');
      print('   → Switching to Render backend: https://backend-o5fa.onrender.com');
      Config.enableRenderFallback();
      // Retry once with Render
      try {
        final response = await http
            .get(Uri.parse('${ApiService.baseUrl}/'))
            .timeout(Duration(seconds: 8));
        if (response.statusCode == 200) {
          print('   ✅ Render backend reachable');
          return;
        }
      } catch (_) {}
      print('   ❌ Render backend also unreachable. Check internet or deployed URL.');
      return;
    }

    // Test 2: Check authentication
    print('\n2️⃣  Testing Supabase authentication...');
    final token = await ApiService.getAuthToken();
    if (token != null) {
      print('   ✅ Auth token obtained');
      print('   Token length: ${token.length}');
    } else {
      print('   ⚠️  No Supabase session');
      print('   💡 You must login first before API calls work');
      print('   Skipping /predict endpoint test...\n');
      return;
    }

    // Test 3: Test actual API endpoint
    print('\n3️⃣  Testing /predict endpoint...');
    try {
      final testData = SleepInput(
        gender: 'Male',
        age: 28,
        occupation: 'Engineer',
        sleepDuration: 7.0,
        physicalActivityLevel: 60,
        stressLevel: 5,
        bmiCategory: 'Normal',
        systolic: 120,
        diastolic: 80,
        sleepQuality: 8,
        deepSleepPct: 15.5,
        remSleepPct: 22.3,
        sleepPercent: 85.0,
      );

      final response = await ApiService.predictSleep(testData);
      if (response != null) {
        print('   ✅ /predict endpoint working');
        print('   Sleep Score: ${response.sleepScore}');
        print('   Score Band: ${response.scoreBand}');
        print('   Sleep Quality: ${response.sleepQuality}');
        print('   Deep Sleep: ${response.deepSleepPct}%');
        print('   REM Sleep: ${response.remSleepPct}%');
        print('   Sleep Percent: ${response.sleepPercent}%');
        print('   Strategies: ${response.strategies.length} recommendations');
      } else {
        print('   ❌ /predict returned null');
        print('   💡 Check backend logs for detailed error');
      }
    } catch (e) {
      print('   ❌ /predict failed');
      print('   Error: $e');
    }

    print('\n' + '=' * 60);
    print('✨ Connection test complete');
    print('=' * 60 + '\n');
  }

  /// Quick health check (returns boolean)
  static Future<bool> quickHealthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiService.baseUrl}/'))
          .timeout(Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
