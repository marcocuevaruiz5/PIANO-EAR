/// Resultado/estadísticas de una sesión de práctica en el Modo Aprendizaje.
class PracticeResult {
  final String songId;
  final DateTime date;
  final int correctNotes;
  final int wrongNotes;
  final int missedNotes;
  final int totalExpectedNotes;

  const PracticeResult({
    required this.songId,
    required this.date,
    required this.correctNotes,
    required this.wrongNotes,
    required this.missedNotes,
    required this.totalExpectedNotes,
  });

  double get accuracyPercent {
    if (totalExpectedNotes == 0) return 0;
    return (correctNotes / totalExpectedNotes) * 100.0;
  }

  Map<String, dynamic> toRow() => {
        'song_id': songId,
        'date': date.toIso8601String(),
        'correct': correctNotes,
        'wrong': wrongNotes,
        'missed': missedNotes,
        'total_expected': totalExpectedNotes,
      };

  factory PracticeResult.fromRow(Map<String, dynamic> row) => PracticeResult(
        songId: row['song_id'] as String,
        date: DateTime.parse(row['date'] as String),
        correctNotes: row['correct'] as int,
        wrongNotes: row['wrong'] as int,
        missedNotes: row['missed'] as int,
        totalExpectedNotes: row['total_expected'] as int,
      );
}
