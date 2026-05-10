import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _latestPrediction;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLatestPrediction();
  }

  Future<void> _loadLatestPrediction() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await _supabase
          .from('predictions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      setState(() {
        _latestPrediction = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading prediction: $e');
    }
  }

  Color _bandColor(String scoreBand) {
    switch (scoreBand.toLowerCase()) {
      case 'critical':
        return const Color(0xFFD32F2F);
      case 'poor':
        return const Color(0xFFE64A19);
      case 'fair':
        return const Color(0xFFF9A825);
      case 'good':
        return const Color(0xFF388E3C);
      case 'excellent':
        return const Color(0xFF1565C0);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(
          color: Color(0xFFB06EF3), // Purple back button
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB06EF3),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Latest Prediction Results Section
                  if (_latestPrediction != null) ...[
                    const Text(
                      'Latest Sleep Prediction',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPredictionCard(_latestPrediction!),
                    const SizedBox(height: 24),
                  ],

                  // Other notifications placeholder
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationCard(
                    icon: Icons.info_outline,
                    title: 'Welcome to Nindra!',
                    message: 'Start your sleep improvement journey by taking your first prediction.',
                    time: 'Just now',
                    color: const Color(0xFFB06EF3),
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationCard(
                    icon: Icons.lightbulb_outline,
                    title: 'Tip of the Day',
                    message: 'Consistent sleep schedules can improve your sleep quality significantly.',
                    time: '2 hours ago',
                    color: const Color(0xFF5DDFB2),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> prediction) {
    final double sleepScore = (prediction['sleep_score'] as num?)?.toDouble() ?? 0.0;
    final String scoreBand = prediction['score_band'] as String? ?? 'Unknown';
    final String overall = prediction['overall'] as String? ?? 'No assessment available';
    final List<String> priorityFixes = List<String>.from(prediction['priority_fixes'] ?? []);
    final List<String> strategies = List<String>.from(prediction['strategies'] ?? []);
    final List<String> warnings = List<String>.from(prediction['warnings'] ?? []);
    final List<String> positives = List<String>.from(prediction['positives'] ?? []);

    final bandColor = _bandColor(scoreBand);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252535),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score Display
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bandColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: bandColor, width: 1.5),
                ),
                child: Text(
                  sleepScore.toStringAsFixed(1),
                  style: TextStyle(
                    color: bandColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sleep Score',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: bandColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        scoreBand,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Overall Assessment
          Text(
            'Assessment',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            overall,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Priority Fixes
          if (priorityFixes.isNotEmpty) ...[
            const Text(
              'Priority Fixes',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...priorityFixes.map(
              (fix) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.white70)),
                    Expanded(
                      child: Text(
                        fix,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Strategies
          if (strategies.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Strategies',
              style: TextStyle(
                color: Color(0xFF5DDFB2),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...strategies.map(
              (strategy) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.white70)),
                    Expanded(
                      child: Text(
                        strategy,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Warnings
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Warnings',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.white70)),
                    Expanded(
                      child: Text(
                        warning,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Positives
          if (positives.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Positives',
              style: TextStyle(
                color: Color(0xFF5DDFB2),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...positives.map(
              (positive) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.white70)),
                    Expanded(
                      child: Text(
                        positive,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String message,
    required String time,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252535),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}