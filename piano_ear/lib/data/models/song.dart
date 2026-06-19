import 'dart:convert';
import 'note_event.dart';

/// Una interpretación grabada y transcrita: metadatos + lista de notas.
class Song {
  final String id;
  final String title;
  final DateTime createdAt;

  /// Duración total de la grabación, en ms.
  final int durationMs;

  /// Tempo estimado (negras por minuto).
  final double tempoBpm;

  final int timeSignatureNumerator;
  final int timeSignatureDenominator;

  /// Tonalidad estimada, ej. "C major", "A minor". Puede ser null si aún
  /// no se ha estimado.
  final String? keySignature;

  final List<NoteEvent> notes;

  /// Ruta del archivo de audio (.wav/.aac) grabado, para reproducción.
  final String? audioFilePath;

  const Song({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.durationMs,
    required this.tempoBpm,
    required this.notes,
    this.timeSignatureNumerator = 4,
    this.timeSignatureDenominator = 4,
    this.keySignature,
    this.audioFilePath,
  });

  Song copyWith({String? title}) => Song(
        id: id,
        title: title ?? this.title,
        createdAt: createdAt,
        durationMs: durationMs,
        tempoBpm: tempoBpm,
        notes: notes,
        timeSignatureNumerator: timeSignatureNumerator,
        timeSignatureDenominator: timeSignatureDenominator,
        keySignature: keySignature,
        audioFilePath: audioFilePath,
      );

  String get durationLabel {
    final totalSeconds = (durationMs / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'title': title,
        'created_at': createdAt.toIso8601String(),
        'duration_ms': durationMs,
        'tempo_bpm': tempoBpm,
        'ts_num': timeSignatureNumerator,
        'ts_den': timeSignatureDenominator,
        'key_signature': keySignature,
        'audio_path': audioFilePath,
        'notes_json': jsonEncode(notes.map((n) => n.toJson()).toList()),
      };

  factory Song.fromRow(Map<String, dynamic> row) {
    final notesRaw = jsonDecode(row['notes_json'] as String) as List;
    return Song(
      id: row['id'] as String,
      title: row['title'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      durationMs: row['duration_ms'] as int,
      tempoBpm: (row['tempo_bpm'] as num).toDouble(),
      timeSignatureNumerator: row['ts_num'] as int,
      timeSignatureDenominator: row['ts_den'] as int,
      keySignature: row['key_signature'] as String?,
      audioFilePath: row['audio_path'] as String?,
      notes: notesRaw
          .map((e) => NoteEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
