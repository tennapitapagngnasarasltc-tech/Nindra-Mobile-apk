import 'package:flutter/material.dart';
import 'package:nindra/services/api_service.dart';
import 'package:nindra/models/user_suggestion.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  static const int _pageSize = 20;

  final List<UserSuggestion> _suggestions = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _scoreBand;
  String? _message;
  String? _error;
  int _nextOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadPage(reset: true);
  }

  Future<void> _loadPage({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _message = null;
        _suggestions.clear();
        _nextOffset = 0;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final response = await ApiService.getUserSuggestions(
        limit: _pageSize,
        offset: reset ? 0 : _nextOffset,
        expectedScoreBand: reset ? null : _scoreBand,
      );
      if (!mounted) return;

      final status = response['status'] as String? ?? 'ok';
      final band = response['score_band'] as String?;
      if (status == 'band_changed') {
        setState(() {
          _suggestions.clear();
          _scoreBand = band;
          _message = response['message'] as String?;
          _hasMore = false;
          _loading = false;
          _loadingMore = false;
        });
        return;
      }

      final rows = response['suggestions'] as List? ?? const [];
      setState(() {
        _scoreBand = band;
        _suggestions.addAll(
          rows.map(
            (row) =>
                UserSuggestion.fromMap(Map<String, dynamic>.from(row as Map)),
          ),
        );
        _message = response['message'] as String?;
        _hasMore = response['has_more'] as bool? ?? false;
        _nextOffset = response['next_offset'] as int? ?? _nextOffset;
        _loading = false;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text('Recommended for You'),
        actions: [
          IconButton(
            tooltip: 'Refresh suggestions',
            onPressed: _loading ? null : () => _loadPage(reset: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFB06EF3)),
              )
            : _error != null
            ? _buildMessage(
                'Could not load suggestions',
                _error!,
                actionLabel: 'Retry',
                onAction: () => _loadPage(reset: true),
              )
            : _suggestions.isEmpty
            ? _buildMessage(
                _emptyTitle,
                _message ?? 'No suggestions are available right now.',
                actionLabel: _message?.contains('changed') == true
                    ? 'Refresh'
                    : null,
                onAction: () => _loadPage(reset: true),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_scoreBand != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Text(
                        'Sleep quality: $_scoreBand',
                        style: const TextStyle(
                          color: Color(0xFFB06EF3),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _SuggestionListItem(suggestion: _suggestions[index]),
                    ),
                  ),
                  if (_hasMore)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _loadingMore
                              ? null
                              : () => _loadPage(reset: false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB06EF3),
                            side: const BorderSide(color: Color(0xFF6A3C8A)),
                          ),
                          child: _loadingMore
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFB06EF3),
                                  ),
                                )
                              : const Text('Load more'),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  String get _emptyTitle {
    if (_message?.contains('prediction') == true) return 'No prediction yet';
    if (_message?.contains('score band') == true) return 'No score band';
    return 'No matching suggestions';
  }

  Widget _buildMessage(
    String title,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.55)),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestionListItem extends StatelessWidget {
  final UserSuggestion suggestion;

  const _SuggestionListItem({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF252535),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            suggestion.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            suggestion.suggestionNote,
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

