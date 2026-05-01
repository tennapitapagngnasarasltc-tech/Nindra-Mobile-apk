import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nindra/config.dart';

class ApiService {

  static String get baseUrl => Config.apiBaseUrl;

  static Future<void> runAI() async {

    final session =
        Supabase.instance.client.auth.currentSession;

    print("Session: $session");

    if (session == null) {
      print("No session, returning");
      return;
    }

    final token = session.accessToken;

    print("Token: ${token.substring(0, 20)}...");

    print("Posting to $baseUrl/run-ai");

    final response = await http.post(
      Uri.parse("$baseUrl/run-ai"),

      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");
  }
}