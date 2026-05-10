import 'dart:async';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────
class UserSuggestion {
  final int id;
  final String title;
  final String suggestion;
  final DateTime createdAt;

  const UserSuggestion({
    required this.id,
    required this.title,
    required this.suggestion,
    required this.createdAt,
  });

  factory UserSuggestion.fromMap(Map<String, dynamic> map) => UserSuggestion(
    id: map['id'] as int,
    title: map['title'] as String,
    suggestion: map['suggestion'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}

// ─────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  // Profile / stats
  String _username = '';
  String? _profileImageUrl;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  // Latest prediction from profile
  double? _latestScore;
  String? _latestScoreBand;

  // Real-time subscriptions
  StreamSubscription? _profileSubscription;
  StreamSubscription? _suggestionsSubscription;

  double? _sleepDuration;
  double? _sleepPercent;
  double? _deepSleepPct;
  double? _remSleepPct;
  int? _sleepQuality; // Changed from String to int (1-10 scale)

  // Suggestions
  List<UserSuggestion> _suggestions = [];
  bool _suggestionsLoading = true;
  String? _suggestionsError;



  @override
  void initState() {
    super.initState();
    _setupRealTimeSubscriptions();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _suggestionsSubscription?.cancel();
    super.dispose();
  }

  // ── Real-time subscriptions ────────────────────────────────────────────
  void _setupRealTimeSubscriptions() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _username = 'User';
        _isLoading = false;
        _suggestionsLoading = false;
        _suggestionsError = 'Not authenticated';
      });
      return;
    }

    // Profile subscription
    _profileSubscription = _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen(
          (List<Map<String, dynamic>> data) {
            if (data.isNotEmpty && mounted) {
              final response = data.first;
              setState(() {
                _username = response['username'] ?? 'User';
                _profileImageUrl = response['profile_image_url'] as String?;
                _sleepDuration = (response['sleep_duration'] as num?)
                    ?.toDouble();
                _sleepPercent = (response['sleep_percent'] as num?)?.toDouble();
                _deepSleepPct = (response['deep_sleep_pct'] as num?)
                    ?.toDouble();
                _remSleepPct = (response['rem_sleep_pct'] as num?)?.toDouble();
                _sleepQuality = (response['sleep_quality'] as num?)
                    ?.toInt(); // Convert to int
                _latestScore = (response['latest_score'] as num?)?.toDouble();
                _latestScoreBand = response['score_band'] as String?;
                _isLoading = false;
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _username = 'User';
                _isLoading = false;
              });
            }
          },
        );

    // Suggestions subscription
    _suggestionsSubscription = _supabase
        .from('user_suggestions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen(
          (List<Map<String, dynamic>> data) {
            if (mounted) {
              setState(() {
                _suggestions = data
                    .map((e) => UserSuggestion.fromMap(e))
                    .toList();
                _suggestionsLoading = false;
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _suggestionsError = error.toString();
                _suggestionsLoading = false;
              });
            }
          },
        );
  }

  String get _formattedDate =>
    DateFormat('dd MMM yyyy').format(_selectedDate).toLowerCase();

  // ── Helpers ────────────────────────────────────────────────────────────
  String _fmtHours(double? v) =>
      v != null ? '${v.toStringAsFixed(1)} hrs' : '—';

  String _fmtPct(double? v) => v != null ? '${v.toStringAsFixed(0)}%' : '—';

  Color _getSleepQualityColor(int? quality) {
    if (quality == null) return const Color(0xFF5DDFB2); // Default green
    if (quality >= 8) return const Color(0xFF5DDFB2); // Excellent - Green
    if (quality >= 7) return const Color(0xFFB06EF3); // Good - Purple
    if (quality >= 6) return const Color(0xFFFFD700); // Fair - Yellow
    if (quality >= 5) return const Color(0xFFFF6B6B); // Poor - Red
    return const Color(0xFFFF0000); // Critical - Dark Red
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset('assets/Home.png', fit: BoxFit.cover),
          Container(color: const Color(0xFF1A1A2E).withOpacity(0.75)),

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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),


        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/profile');
          },
          child: _buildProfileAvatar(),
        ),
        Text(
          _formattedDate,
          style: const TextStyle(
            color: Color.fromARGB(190, 255, 255, 255),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/notifications');
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color.fromARGB(209, 255, 255, 255),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF070707),
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFFB06EF3),
            Color(0xFF9B59B6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E30),
            shape: BoxShape.circle,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: _profileImageUrl != null
                ? Image.network(
                    _profileImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                  )
                : _buildDefaultAvatar(),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF2A2A40),
      child: const Icon(
        Icons.person,
        size: 30,
        color: Color(0xFFB06EF3),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // GREETING
  // ─────────────────────────────────────────────
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
                        color: Color(0xFFB06EF3),
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
          'We hope you are doing great today.',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SECTION LABEL
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // STATS GRID  (data from profiles table)
  // ─────────────────────────────────────────────
  Widget _buildStatsGrid() {
    if (_isLoading) {
      return Column(
        children: List.generate(
          2,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF252535).withOpacity(0.6),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildStatRow(
          leftLabel: 'Total Sleep\nDuration',
          leftValue: _fmtHours(_sleepDuration),
          leftValueColor: const Color(0xFFB06EF3),
          leftIcon: 'assets/icon1.png',
          rightLabel: 'Sleep Quality',
          rightValue:
              '${_sleepQuality ?? '—'}/10${_sleepPercent != null ? ' (${_sleepPercent!.toStringAsFixed(0)}%)' : ''}',
          rightValueColor: _getSleepQualityColor(_sleepQuality),
          rightIcon: 'assets/icon4.png',
        ),
        const SizedBox(height: 14),
        _buildStatRow(
          leftLabel: 'Deep Sleep',
          leftValue: _fmtPct(_deepSleepPct),
          leftValueColor: const Color(0xFFB06EF3),
          leftIcon: 'assets/icon2.png',
          rightLabel: 'REM Sleep',
          rightValue: _fmtPct(_remSleepPct),
          rightValueColor: const Color(0xFFB06EF3),
          rightIcon: 'assets/icon3.png',
        ),
        const SizedBox(height: 14),
        _buildStatRow(
          leftLabel: 'Sleep Score',
          leftValue: _latestScore?.toStringAsFixed(1) ?? '—',
          leftValueColor: const Color(0xFFB06EF3),
          leftIcon: 'assets/icon4.png',
          rightLabel: 'Score Band',
          rightValue: _latestScoreBand ?? '—',
          rightValueColor: _getScoreBandColor(_latestScoreBand),
          rightIcon: 'assets/icon6.png',
        ),
      ],
    );
  }



  Color _getScoreBandColor(String? band) {
    switch (band?.toLowerCase()) {
      case 'excellent':
        return const Color(0xFF5DDFB2);
      case 'good':
        return const Color(0xFFB06EF3);
      case 'fair':
        return const Color(0xFFFFD700);
      case 'poor':
        return const Color(0xFFFF6B6B);
      case 'critical':
        return const Color(0xFFFF0000);
      default:
        return const Color(0xFF5DDFB2);
    }
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
            const VerticalDivider(
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
               Image.asset(iconPath, width: 48, height: 48),
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

  // ─────────────────────────────────────────────
  // RECOMMENDED HEADER
  // ─────────────────────────────────────────────
  Widget _buildRecommendedHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionLabel('Recommended for You'),
        GestureDetector(
          onTap: () {}, // TODO: navigate to all
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

  // ─────────────────────────────────────────────
  // RECOMMENDED ACTIVITIES  (from user_suggestions)
  // ─────────────────────────────────────────────
  Widget _buildRecommendedActivities() {
    if (_suggestionsLoading) return const _SuggestionsLoadingState();

    if (_suggestionsError != null) {
      return _SuggestionsErrorState(error: _suggestionsError!);
    }

    if (_suggestions.isEmpty) return const _SuggestionsEmptyState();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _SuggestionCard(suggestion: _suggestions[index], index: index),
    );
  }
}

// ─────────────────────────────────────────────
// SUGGESTION CARD
// ─────────────────────────────────────────────
class _SuggestionCard extends StatelessWidget {
  final UserSuggestion suggestion;
  final int index;

  const _SuggestionCard({required this.suggestion, required this.index});

  static const List<Color> _accents = [
    Color(0xFFB06EF3),
    Color(0xFF6EB5F3),
    Color(0xFFF36EB0),
    Color(0xFF6EF3C2),
    Color(0xFFF3C26E),
  ];

  static const List<_IconType> _icons = _IconType.values;

  @override
  Widget build(BuildContext context) {
    final accent = _accents[index % _accents.length];
    final iconType = _icons[index % _icons.length];

    return GestureDetector(
      onTap: () => _SuggestionDetailSheet.show(context, suggestion, accent),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF252535).withOpacity(0.90),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(24, 24),
                  painter: _IconPainter(icon: iconType, color: accent),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    suggestion.suggestion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.50),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.25),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────
class _SuggestionDetailSheet extends StatelessWidget {
  final UserSuggestion suggestion;
  final Color accent;

  const _SuggestionDetailSheet({
    required this.suggestion,
    required this.accent,
  });

  static void show(BuildContext ctx, UserSuggestion s, Color accent) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SuggestionDetailSheet(suggestion: s, accent: accent),
    );
  }

  String _formatDate(DateTime dt) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          suggestion.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(suggestion.createdAt),
                    style: TextStyle(
                      color: accent.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.white.withOpacity(0.08)),
                  const SizedBox(height: 20),
                  Text(
                    suggestion.suggestion,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.82),
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CUSTOM PAINTED ICONS
// ─────────────────────────────────────────────
enum _IconType { spark, leaf, wave, star, moon }

class _IconPainter extends CustomPainter {
  final _IconType icon;
  final Color color;

  _IconPainter({required this.icon, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (icon) {
      case _IconType.spark:
        _drawSpark(canvas, size, fill);
      case _IconType.leaf:
        _drawLeaf(canvas, size, fill, stroke);
      case _IconType.wave:
        _drawWave(canvas, size, stroke);
      case _IconType.star:
        _drawStar(canvas, size, fill);
      case _IconType.moon:
        _drawMoon(canvas, size, fill);
    }
  }

  void _drawSpark(Canvas c, Size s, Paint fill) {
    final cx = s.width / 2, cy = s.height / 2;
    final path = Path()
      ..moveTo(cx, cy - 10)
      ..lineTo(cx + 3, cy - 3)
      ..lineTo(cx + 10, cy)
      ..lineTo(cx + 3, cy + 3)
      ..lineTo(cx, cy + 10)
      ..lineTo(cx - 3, cy + 3)
      ..lineTo(cx - 10, cy)
      ..lineTo(cx - 3, cy - 3)
      ..close();
    c.drawPath(path, fill);
    c.drawCircle(Offset(cx + 7, cy - 7), 1.8, fill);
  }

  void _drawLeaf(Canvas c, Size s, Paint fill, Paint stroke) {
    final path = Path()
      ..moveTo(s.width * 0.5, s.height * 0.1)
      ..cubicTo(
        s.width * 0.9,
        s.height * 0.1,
        s.width * 0.9,
        s.height * 0.9,
        s.width * 0.5,
        s.height * 0.9,
      )
      ..cubicTo(
        s.width * 0.1,
        s.height * 0.9,
        s.width * 0.1,
        s.height * 0.1,
        s.width * 0.5,
        s.height * 0.1,
      )
      ..close();
    c.drawPath(path, fill..color = color.withOpacity(0.3));
    c.drawPath(path, stroke);
    c.drawLine(
      Offset(s.width * 0.5, s.height * 0.15),
      Offset(s.width * 0.5, s.height * 0.85),
      stroke,
    );
  }

  void _drawWave(Canvas c, Size s, Paint stroke) {
    for (int i = 0; i < 3; i++) {
      final yBase = s.height * (0.3 + i * 0.2);
      final path = Path()..moveTo(0, yBase);
      path.cubicTo(
        s.width * 0.25,
        yBase - 4,
        s.width * 0.5,
        yBase + 4,
        s.width * 0.75,
        yBase - 4,
      );
      path.cubicTo(s.width * 0.875, yBase - 8, s.width, yBase, s.width, yBase);
      c.drawPath(path, stroke..strokeWidth = 1.8 - i * 0.3);
    }
  }

  void _drawStar(Canvas c, Size s, Paint fill) {
    final cx = s.width / 2, cy = s.height / 2;
    const n = 5;
    final outerR = s.width * 0.46, innerR = s.width * 0.2;
    final path = Path();
    for (int i = 0; i < n * 2; i++) {
      final angle = (i * math.pi / n) - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    c.drawPath(path, fill);
  }

  void _drawMoon(Canvas c, Size s, Paint fill) {
    final outer = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(s.width * 0.5, s.height * 0.5),
          radius: s.width * 0.42,
        ),
      );
    final cut = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(s.width * 0.65, s.height * 0.38),
          radius: s.width * 0.35,
        ),
      );
    c.drawPath(Path.combine(PathOperation.difference, outer, cut), fill);
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.icon != icon || old.color != color;
}

// ─────────────────────────────────────────────
// SUGGESTION STATES
// ─────────────────────────────────────────────
class _SuggestionsLoadingState extends StatelessWidget {
  const _SuggestionsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFF252535).withOpacity(0.6),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionsErrorState extends StatelessWidget {
  final String error;

  const _SuggestionsErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'Could not load suggestions',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Restart subscriptions
              final state = context.findAncestorStateOfType<_HomeScreenState>();
              state?._profileSubscription?.cancel();
              state?._suggestionsSubscription?.cancel();
              state?._setupRealTimeSubscriptions();
            },
            child: const Text(
              'Retry',
              style: TextStyle(color: Color(0xFFB06EF3)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsEmptyState extends StatelessWidget {
  const _SuggestionsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No suggestions yet — check back soon!',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
        ),
      ),
    );
  }
}
