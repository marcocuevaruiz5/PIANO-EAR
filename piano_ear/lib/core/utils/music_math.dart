import 'dart:math' as math;

/// Conversión entre frecuencia (Hz), número MIDI y figuras musicales.
class MusicMath {
  MusicMath._();

  static double midiToFrequency(double midi) {
    return 440.0 * math.pow(2.0, (midi - 69.0) / 12.0);
  }

  /// Convierte una frecuencia en Hz al número MIDI más cercano (double,
  /// para conservar el "cents" de desafinación antes de redondear).
  static double frequencyToMidi(double freqHz) {
    return 69.0 + 12.0 * (math.log(freqHz / 440.0) / math.ln2);
  }

  static int frequencyToNearestMidi(double freqHz) {
    return frequencyToMidi(freqHz).round();
  }

  /// Diferencia en cents entre una frecuencia y la nota MIDI más cercana.
  static double centsOffFromNearestMidi(double freqHz) {
    final exact = frequencyToMidi(freqHz);
    return (exact - exact.round()) * 100.0;
  }

  /// Dada una duración en milisegundos y el tempo (BPM), devuelve la figura
  /// musical estándar más cercana ("whole", "half", "quarter", "eighth",
  /// "sixteenth") junto con su duración en beats. Esto es una cuantización
  /// simplificada: no maneja tresillos compuestos ni ligaduras complejas.
  static NoteValue quantizeDuration({
    required double durationMs,
    required double bpm,
  }) {
    final beatMs = 60000.0 / bpm;
    final beats = durationMs / beatMs;

    const candidates = <double, NoteValue>{
      4.0: NoteValue.whole,
      2.0: NoteValue.half,
      1.5: NoteValue.dottedQuarter,
      1.0: NoteValue.quarter,
      0.75: NoteValue.dottedEighth,
      0.5: NoteValue.eighth,
      0.25: NoteValue.sixteenth,
    };

    double bestBeats = 1.0;
    NoteValue bestValue = NoteValue.quarter;
    double bestDiff = double.infinity;
    candidates.forEach((beatLength, value) {
      final diff = (beats - beatLength).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestBeats = beatLength;
        bestValue = value;
      }
    });
    return bestValue..beatsOverride = bestBeats;
  }
}

/// Representa una figura musical (duración relativa en beats/negras).
class NoteValue {
  final String label;
  final double beats;
  double? beatsOverride;

  NoteValue._(this.label, this.beats);

  static final whole = NoteValue._('whole', 4.0);
  static final half = NoteValue._('half', 2.0);
  static final dottedQuarter = NoteValue._('dottedQuarter', 1.5);
  static final quarter = NoteValue._('quarter', 1.0);
  static final dottedEighth = NoteValue._('dottedEighth', 0.75);
  static final eighth = NoteValue._('eighth', 0.5);
  static final sixteenth = NoteValue._('sixteenth', 0.25);

  double get effectiveBeats => beatsOverride ?? beats;

  /// true si la cabeza de nota debe dibujarse hueca (blanca/redonda).
  bool get isHollowHead => label == 'whole' || label == 'half';

  /// número de "banderas"/corchetes en la plica (0 = negra/blanca/redonda).
  int get flagCount {
    switch (label) {
      case 'eighth':
      case 'dottedEighth':
        return 1;
      case 'sixteenth':
        return 2;
      default:
        return 0;
    }
  }

  bool get isDotted => label.startsWith('dotted');
}
