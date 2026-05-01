import 'package:nindra/config.dart';
import 'package:flutter/material.dart';
import 'package:nindra/screens/splash_screen.dart';
import 'package:nindra/Authentication/signup.dart';
import 'package:nindra/screens/main_navigation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nindra/Authentication/login_screen.dart';
import 'package:nindra/Authentication/welcome_screen.dart';
                // ✅ your nav bar wrapper

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseAnonKey,
  );
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
        '/splash':   (context) => const SplashScreen(),
        '/welcome':  (context) => const WelcomeScreen(),
        '/signup':   (context) => const FullSignUpScreen(),
        '/signin':   (context) => const SignInScreen(),

        // ── Nav bar lives here (HomeScreen + all tabs) ──────────
        '/home':     (context) => const MainNavigation(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}