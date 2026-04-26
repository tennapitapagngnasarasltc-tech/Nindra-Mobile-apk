import 'package:nindra/config.dart';
import 'package:flutter/material.dart';
import 'package:nindra/entertainment.dart';
import 'package:nindra/Authentication/signup.dart';
import 'package:nindra/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nindra/Authentication/welcome_screen.dart';



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
      title: 'Audio Player',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        // '/signin': (context) => const EntertainmentScreen(),
        '/signin': (context) => const MainWelcomeScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}