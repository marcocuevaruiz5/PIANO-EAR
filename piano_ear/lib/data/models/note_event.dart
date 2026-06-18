/// Representa una nota individual detectada (o programada) en una
/// interpretación: su altura (MIDI), momento de inicio, duración y
/// "velocity" (intensidad, 0-127, estilo MIDI).
///
/// Varias [NoteEvent] con tiempos de inicio muy cercanos entre sí forman
/// un acorde — no existe una clase `Chord` separada: un acorde es,
/// simplemente, un grupo de NoteEvent simultáneos. Esto simplifica el
/// modelo de datos y la serialización.
class NoteEvent {
  /// Número MIDI (21 = A0 ... 108 = C8).
  final int midi;

  /// Frecuencia fundamental medida en Hz (puede diferir levemente del
  /// valor "ideal" de [midi] por desafinación; se guarda para análisis).
  final double frequencyHz;

  /// Instante de inicio relativo al comienzo de la grabación, en ms.
  final int startTimeMs;

  /// Duración medida, en ms.
  final int durationMs;

  /// Intensidad estimada a partir de la energía de la señal (0-127).
  final int velocity;

  const NoteEvent({
    required this.midi,
    required this.frequencyHz,
    required this.startTimeMs,
    required this.durationMs,
    required this.velocity,
  });

  int get endTimeMs => startTimeMs + durationMs;

  NoteEvent copyWith({int? durationMs, int? velocity}) => NoteEvent(
        midi: midi,
        frequencyHz: frequencyHz,
        startTimeMs: startTimeMs,
        durationMs: durationMs ?? this.durationMs,
        velocity: velocity ?? this.velocity,
      );

  Map<String, dynamic> toJson() => {
        'midi': midi,
        'freq': frequencyHz,
        'start': startTimeMs,
        'dur': durationMs,
        'vel': velocity,
      };

  factory NoteEvent.fromJson(Map<String, dynamic> json) => NoteEvent(
        midi: json['midi'] as int,
        frequencyHz: (json['freq'] as num).toDouble(),
        startTimeMs: json['start'] as int,
        durationMs: json['dur'] as int,
        velocity: json['vel'] as int,
      );
}

/// Agrupa notas que comparten (aproximadamente) el mismo instante de
/// inicio — útil para renderizar partitura y para el modo de aprendizaje,
/// donde el alumno debe pulsar todas las teclas de un acorde a la vez.
class NoteGroup {
  final int startTimeMs;
  final List<NoteEvent> notes;

  NoteGroup({required this.startTimeMs, required this.notes});

  bool get isChord => notes.length > 1;

  Set<int> get midiSet => notes.map((n) => n.midi).toSet();

  /// Agrupa una lista de notas (ordenada o no) en acordes, considerando
  /// simultáneas las que empiezan dentro de [windowMs] entre sí.
  static List<NoteGroup> groupByOnset(
    List<NoteEvent> notes, {
    int windowMs = 60,
  }) {
    final sorted = [...notes]..sort((a, b) => a.startTimeMs.compareTo(b.startTimeMs));
    final groups = <NoteGroup>[];
    for (final note in sorted) {
      if (groups.isNotEmpty &&
          (note.startTimeMs - groups.last.startTimeMs).abs() <= windowMs) {
        groups.last.notes.add(note);
      } else {
        groups.add(NoteGroup(startTimeMs: note.startTimeMs, notes: [note]));
      }
    }
    return groups;
  }
}
