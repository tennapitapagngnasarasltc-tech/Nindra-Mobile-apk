import 'package:nindra/config.dart';
import 'package:flutter/material.dart';
import 'package:nindra/screens/splash_screen.dart';
import 'package:nindra/Authentication/signup.dart';
import 'package:nindra/screens/main_navigation.dart';
import 'package:nindra/services/connection_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nindra/Authentication/login_screen.dart';
import 'package:nindra/Authentication/welcome_screen.dart';
import 'package:nindra/screens/prediction_result_screen.dart';
import 'package:nindra/screens/sleep_prediction_form_screen.dart';
import 'package:nindra/screens/notifications_screen.dart';
// ✅ your nav bar wrapper

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseAnonKey,
  );

  // 🔍 Connection test on app startup
  print('\n📱 Nindra app starting...');
  await ConnectionTest.runFullTest();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nindra',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB06EF3)),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      routes: {
        // ── No nav bar ──────────────────────────────────────────
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/signup': (context) => const FullSignUpScreen(),
        '/signin': (context) => const SignInScreen(),

        // ── Nav bar lives here (HomeScreen + all tabs) ──────────
        '/home': (context) => const MainNavigation(),

        // ── Prediction screens ──────────────────────────────────
        '/predict': (context) => const SleepPredictionFormScreen(),
        '/result': (context) => const PredictionResultScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
