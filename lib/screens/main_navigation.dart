import 'package:flutter/material.dart';
import 'package:nindra/entertainment.dart';
import 'package:nindra/screens/homescreen.dart';
import 'package:nindra/services/api_service.dart';
import 'package:nindra/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const EntertainmentScreen(),
    const ProfileScreen(),
  ];

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: FontAwesomeIcons.house,
      activeIcon: FontAwesomeIcons.house,
      label: 'Home',
    ),

    _NavItem(
      icon: FontAwesomeIcons.film,
      activeIcon: FontAwesomeIcons.film,
      label: 'Entertainment',
    ),

    _NavItem(
      icon: FontAwesomeIcons.user,
      activeIcon: FontAwesomeIcons.solidUser,
      label: 'Profile',
    ),
  ];

  // Bot animation
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize bounce animation for bot icon
    _bounceController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Removed deprecated background AI trigger because /predict requires user input.
  }

  /// Automatically runs AI engine after login
  Future<void> runAIBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      /// Prevent repeated calls
      final alreadyRan = prefs.getBool("ai_ran") ?? false;

      if (alreadyRan) {
        print("AI already executed");

        return;
      }

      print("Running AI Engine...");

      await ApiService.runAI();

      await prefs.setBool("ai_ran", true);

      print("AI completed successfully");
    } catch (e) {
      print("AI ERROR: $e");
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),

          _buildFloatingNavBar(),

          // Floating Bot
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/predict');
              },
              child: ScaleTransition(
                scale: _bounceAnimation,
                child: Image.asset('assets/bot.png', width: 50, height: 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return Positioned(
      bottom: 16,
      left: 16,

      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),

        decoration: BoxDecoration(
          color: const Color(0xFF1E1E30).withOpacity(0.95),

          borderRadius: BorderRadius.circular(25),

          border: Border.all(
            color: const Color(0xFFB06EF3).withOpacity(0.3),
            width: 0.8,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,

          children: List.generate(_navItems.length, (i) => _buildNavItem(i)),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final bool isSelected = _currentIndex == index;

    final item = _navItems[index];

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },

      behavior: HitTestBehavior.opaque,

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            FaIcon(
              isSelected ? item.activeIcon : item.icon,

              size: 18,

              color: isSelected ? const Color(0xFFB06EF3) : Colors.white54,
            ),

            const SizedBox(height: 2),

            Text(
              item.label,

              style: TextStyle(
                color: isSelected ? const Color(0xFFB06EF3) : Colors.white38,

                fontSize: 9,

                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
