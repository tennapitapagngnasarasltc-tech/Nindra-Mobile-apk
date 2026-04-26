import 'package:flutter/material.dart';
import 'package:nindra/entertainment.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nindra/screens/ai_bot_card.dart'; // Import the AI Bot Card

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoError = false;
  String _username = 'Friend';

  // Sample data for statistics
  int _totalSleepHours = 7;
  int _sleepGoal = 8;
  double _sleepQuality = 85; // percentage
  int _deepSleepHours = 2;
  int _remSleepHours = 2;

  // Sample recent activities
  final List<Map<String, dynamic>> _recentActivities = [
    {
      'title': 'Meditation Session',
      'time': '10:30 PM',
      'duration': '15 min',
      'icon': Icons.self_improvement,
      'color': Colors.purple,
    },
    {
      'title': 'Calming Music',
      'time': '10:00 PM',
      'duration': '30 min',
      'icon': Icons.music_note,
      'color': Colors.blue,
    },
    {
      'title': 'Sleep Tracking',
      'time': '11:00 PM',
      'duration': '7h 30m',
      'icon': Icons.bedtime,
      'color': Colors.green,
    },
    {
      'title': 'Breathing Exercise',
      'time': '09:45 PM',
      'duration': '10 min',
      'icon': Icons.air,
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final auth = Supabase.instance.client.auth;
    Map<String, dynamic>? user;
    for (var attempt = 0; attempt < 5; attempt++) {
      final currentUser = auth.currentUser;
      final currentSessionUser = auth.currentSession?.user;
      if (currentUser != null) {
        user = currentUser.toJson();
        break;
      }
      if (currentSessionUser != null) {
        user = currentSessionUser.toJson();
        break;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final userId = user?['id'] as String?;
    if (userId == null) return;

    final fallbackName =
        user?['email']?.toString().split('@').first ?? 'Friend';

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .single();

      final username = response['username'] as String?;

      if (!mounted) return;
      setState(() {
        _username = username?.isNotEmpty == true ? username! : fallbackName;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Failed to load username: $e');
      if (mounted) {
        setState(() {
          _username = fallbackName;
        });
      }
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset('assets/background.mp4');

    _videoController.addListener(() {
      if (_videoController.value.hasError) {
        setState(() {
          _isVideoError = true;
        });
        print('Video player error: ${_videoController.value.errorDescription}');
      }
    });

    try {
      await _videoController.initialize();
      await _videoController.setLooping(true);
      await _videoController.setVolume(0.0);

      if (mounted) {
        await _videoController.play();
        setState(() {
          _isVideoInitialized = true;
        });
        print('Video initialized and playing successfully');
      }
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _isVideoError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Video
          if (_isVideoInitialized && !_isVideoError)
            SizedBox.expand(child: VideoPlayer(_videoController))
          else
            Container(color: Colors.black),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting Section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hello,',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white70,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Welcome Back, $_username!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10,
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Notification Button
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6B1FA0), Color(0xFF9C27B0)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                // Navigate to notification page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EntertainmentScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Stack(
                                  children: [
                                    const Icon(
                                      Icons.notifications_none,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // AI Bot Card - ADDED HERE
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: AIBotCard(),
                  ),

                  const SizedBox(height: 24),

                  // Sleep Statistics Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sleep Statistics',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _viewAllStats(context);
                              },
                              child: Text(
                                'View All',
                                style: TextStyle(
                                  color: Colors.purple.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Stats Cards Grid
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.3,
                          children: [
                            _buildStatCard(
                              'Total Sleep',
                              '$_totalSleepHours hrs',
                              'Goal: $_sleepGoal hrs',
                              Icons.bedtime,
                              Colors.purple,
                            ),
                            _buildStatCard(
                              'Sleep Quality',
                              '$_sleepQuality%',
                              'Good',
                              Icons.health_and_safety,
                              Colors.green,
                            ),
                            _buildStatCard(
                              'Deep Sleep',
                              '$_deepSleepHours hrs',
                              '25% of total',
                              Icons.nightlight,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              'REM Sleep',
                              '$_remSleepHours hrs',
                              'Great!',
                              Icons.psychology,
                              Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent Activities Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Activities',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Activities List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentActivities.length,
                          itemBuilder: (context, index) {
                            final activity = _recentActivities[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (activity['color'] as Color)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    activity['icon'],
                                    color: activity['color'],
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  activity['title'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  activity['time'],
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    activity['duration'],
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A3E),
          title: const Text(
            'Notifications',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'No new notifications at this moment.\nCheck back later for updates!',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFFCE9FFC)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _viewAllStats(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A3E),
          title: const Text(
            'Detailed Statistics',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Average Sleep', '7.2 hours'),
                const Divider(color: Colors.white24),
                _buildDetailRow('Best Night', '8.5 hours'),
                const Divider(color: Colors.white24),
                _buildDetailRow('Sleep Consistency', '85%'),
                const Divider(color: Colors.white24),
                _buildDetailRow('Times Woken Up', '2 times'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFFCE9FFC)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
