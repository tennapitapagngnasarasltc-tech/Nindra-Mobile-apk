class UserSuggestion {
  final String id;
  final String title;
  final String suggestionNote;
  final String scoreBand;

  const UserSuggestion({
    required this.id,
    required this.title,
    required this.suggestionNote,
    required this.scoreBand,
  });

  factory UserSuggestion.fromMap(Map<String, dynamic> map) => UserSuggestion(
    id: map['id'].toString(),
    title: map['title'] as String? ?? '',
    suggestionNote: map['suggestion_note'] as String? ?? '',
    scoreBand: map['score_band'] as String? ?? '',
  );
}

