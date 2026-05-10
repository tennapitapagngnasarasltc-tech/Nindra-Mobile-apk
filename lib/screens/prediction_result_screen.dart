import 'package:flutter/material.dart';

class PredictionResultScreen extends StatelessWidget {
  const PredictionResultScreen({super.key});

  // ─── Score Band Color Mapping ──────────────────────
  Color _bandColor(String scoreBand) {
    switch (scoreBand) {
      case 'Critical':
        return const Color(0xFFD32F2F);
      case 'Poor':
        return const Color(0xFFE64A19);
      case 'Fair':
        return const Color(0xFFF9A825);
      case 'Good':
        return const Color(0xFF388E3C);
      case 'Excellent':
        return const Color(0xFF1565C0);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Step 1: Receive arguments
    final result =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    // Step 2: Extract all fields
    final double sleepScore = (result['sleep_score'] as num).toDouble();
    final String scoreBand = result['score_band'] as String;
    final String overall = result['overall'] as String;
    final List<String> priorityFixes = List<String>.from(
      result['priority_fixes'] ?? [],
    );
    final List<String> strategies = List<String>.from(
      result['strategies'] ?? [],
    );
    final List<String> warnings = List<String>.from(result['warnings'] ?? []);
    final List<String> positives = List<String>.from(result['positives'] ?? []);

    // Step 3: Get color for this band
    final bandColor = _bandColor(scoreBand);

    // Step 4: Display layout
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Sleep Prediction Result'),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large sleep score number with bandColor
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: bandColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: bandColor, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    sleepScore.toStringAsFixed(2),
                    style: TextStyle(
                      color: bandColor,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Score band label badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: bandColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      scoreBand,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Overall summary text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF252535),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                overall,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section: Priority Fixes
            if (priorityFixes.isNotEmpty) ...[
              const Text(
                'Priority Fixes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...priorityFixes.map(
                (fix) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCardItem(
                    text: fix,
                    backgroundColor: const Color(0xFFFFEBEE),
                    textColor: Colors.red[800]!,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Section: Strategies
            if (strategies.isNotEmpty) ...[
              const Text(
                'Strategies',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...strategies.map(
                (strategy) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCardItem(
                    text: strategy,
                    backgroundColor: const Color(0xFFE3F2FD),
                    textColor: Colors.blue[800]!,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Section: Warnings
            if (warnings.isNotEmpty) ...[
              const Text(
                'Warnings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...warnings.map(
                (warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCardItem(
                    text: warning,
                    backgroundColor: const Color(0xFFFFF3E0),
                    textColor: Colors.orange[800]!,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Section: Positives
            if (positives.isNotEmpty) ...[
              const Text(
                'Positives',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...positives.map(
                (positive) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCardItem(
                    text: positive,
                    backgroundColor: const Color(0xFFE8F5E9),
                    textColor: Colors.green[800]!,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Back button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 29, 17, 41),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Card item builder for recommendations
  Widget _buildCardItem({
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Card(
      color: backgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
