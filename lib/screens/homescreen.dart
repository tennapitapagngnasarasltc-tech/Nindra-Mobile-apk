import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

  String _username = '';
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  // Sleep stats — replace with your actual data source / Supabase fetch
  final int _totalSleepHours = 7;
  final int _sleepQualityPercent = 85;
  final int _deepSleepHours = 7;
  final int _remSleepHours = 3;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _username = 'User';
          _isLoading = false;
        });
        return;
      }

      final response = await _supabase
          .from('profiles')
          .select('username')
          .eq('user_id', userId)
          .single();

      setState(() {
        _username = response['username'] ?? 'User';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _username = 'User';
        _isLoading = false;
      });
    }
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  String get _formattedDate {
    return DateFormat('dd MMM yyyy').format(_selectedDate).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background Image ──────────────────────────────────────────
          Image.asset(
            'assets/Home.png', // 🔁 Replace with your image
            fit: BoxFit.cover,
          ),

          // ── Dark overlay for readability ──────────────────────────────
          Container(
            color: const Color(0xFF1A1A2E).withOpacity(0.75),
          ),

          // ── Main Content ──────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 24),
                  _buildGreeting(),
                  const SizedBox(height: 36),
                  _buildSectionLabel('Statistics'),
                  const SizedBox(height: 14),
                  _buildStatsGrid(),
                  const SizedBox(height: 28),
                  _buildRecommendedHeader(),
                  const SizedBox(height: 14),
                  _buildRecommendedActivities(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Profile avatar
        CircleAvatar(
          radius: 26,
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          backgroundImage: AssetImage(
            'assets/images/profile_avatar.png', // 🔁 Replace with your image
          ),
        ),

        // Date navigator
        Row(
          children: [
            GestureDetector(
              onTap: _previousDay,
              child: const Icon(Icons.chevron_left, color: Colors.white70, size: 22),
            ),
            const SizedBox(width: 8),
            Text(
              _formattedDate,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _nextDay,
              child: const Icon(Icons.chevron_right, color: Colors.white70, size: 22),
            ),
          ],
        ),

        // Notification bell
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 250, 250, 250),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.white12),
          ),
          child: Image.asset(
            'assets/icon.png', // 🔁 Replace with your custom icon
            width: 22,
            height: 22,
            color: const Color.fromARGB(255, 7, 7, 7),
          ),
        ),
      ],
    );
  }

  // ── Greeting ─────────────────────────────────────────────────────────────
  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _isLoading
            ? const SizedBox(
                height: 36,
                width: 160,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white10,
                  color: Color(0xFFB06EF3),
                ),
              )
            : RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Hello ',
                      style: TextStyle(
                        color: Color(0xFFB06EF3), // purple
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: _username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
        const SizedBox(height: 6),
        const Text(
          'We Hope you are doing great Today.',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  // ── Stats 2×2 grid ────────────────────────────────────────────────────────
  Widget _buildStatsGrid() {
    return Column(
      children: [
        // Row 1
        _buildStatRow(
          leftLabel: 'Total Sleep Hours\nYesterday',
          leftValue: '$_totalSleepHours Hours',
          leftValueColor: const Color(0xFFB06EF3),
          leftIcon: 'assets/baby-sleep.png', // 🔁 Replace
          rightLabel: 'Sleep Quality',
          rightValue: '$_sleepQualityPercent% Good',
          rightValueColor: const Color(0xFF5DDFB2),
          rightIcon: 'assets/ico2.png', // 🔁 Replace
        ),
        const SizedBox(height: 14),
        // Row 2
        _buildStatRow(
          leftLabel: 'Deep Sleep Hours\nYesterday',
          leftValue: '$_deepSleepHours Hours',
          leftValueColor: const Color(0xFFB06EF3),
          leftIcon: 'assets/dream.png', // 🔁 Replace
          rightLabel: 'REM Sleep',
          rightValue: '$_remSleepHours Hours',
          rightValueColor: const Color(0xFFB06EF3),
          rightIcon: 'assets/sleep.png', // 🔁 Replace
        ),
      ],
    );
  }

  Widget _buildStatRow({
    required String leftLabel,
    required String leftValue,
    required Color leftValueColor,
    required String leftIcon,
    required String rightLabel,
    required String rightValue,
    required Color rightValueColor,
    required String rightIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252535).withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _buildStatCell(
                label: leftLabel,
                value: leftValue,
                valueColor: leftValueColor,
                iconPath: leftIcon,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.white12,
              indent: 16,
              endIndent: 16,
            ),
            Expanded(
              child: _buildStatCell(
                label: rightLabel,
                value: rightValue,
                valueColor: rightValueColor,
                iconPath: rightIcon,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCell({
    required String label,
    required String value,
    required Color valueColor,
    required String iconPath,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Image.asset(
                iconPath,
                width: 36,
                height: 36,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Recommended Activities ────────────────────────────────────────────────
  Widget _buildRecommendedHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionLabel('Recommended Activities'),
        GestureDetector(
          onTap: () {
            // TODO: Navigate to all activities
          },
          child: const Text(
            'See all',
            style: TextStyle(
              color: Color(0xFFB06EF3),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedActivities() {
    // Placeholder cards — replace with your actual activity data
    final activities = [
      {'title': 'Meditation', 'duration': '10 min', 'icon': 'assets/icons/ic_meditation.png'},
      {'title': 'Light Yoga', 'duration': '20 min', 'icon': 'assets/icons/ic_yoga.png'},
      {'title': 'Deep Breathing', 'duration': '5 min', 'icon': 'assets/icons/ic_breathing.png'},
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: activities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final a = activities[index];
          return Container(
            width: 130,
            decoration: BoxDecoration(
              color: const Color(0xFF252535).withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  a['icon']!, // 🔁 Replace with your custom icon
                  width: 32,
                  height: 32,
                  color: const Color(0xFFB06EF3),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a['title']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      a['duration']!,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}