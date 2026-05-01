import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        Navigator.pushReplacementNamed(context, '/home');    // ✅ → MainNavigation (with nav bar)
      } else {
        Navigator.pushReplacementNamed(context, '/welcome');  // ✅ → no nav bar
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/Transparent.png',
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}