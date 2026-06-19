import 'dart:math' as math;

class MusicMath {
  MusicMath._();

  static double midiToFrequency(double midi) {
    return 440.0 * math.pow(2.0, (midi - 69.0) / 12.0);
  }

  static double frequencyToMidi(double freqHz) {
    return 69.0 + 12.0 * (math.log(freqHz / 440.0) / math.ln2);
  }

  static int frequencyToNearestMidi(double freqHz) {
    return frequencyToMidi(freqHz).round();
  }

  static NoteValue quantizeDuration({
    required double durationMs,
    required double bpm,
  }) {
    final beatMs = 60000.0 / bpm;
    final beats = durationMs / beatMs;

    // NO const aqui — NoteValue no es const
    final candidates = <double, NoteValue>{
      4.0: NoteValue.whole,
      2.0: NoteValue.half,
      1.5: NoteValue.dottedQuarter,
      1.0: NoteValue.quarter,
      0.75: NoteValue.dottedEighth,
      0.5: NoteValue.eighth,
      0.25: NoteValue.sixteenth,
    };

    NoteValue bestValue = NoteValue.quarter;
    double bestDiff = double.infinity;
    candidates.forEach((beatLength, value) {
      final diff = (beats - beatLength).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestValue = value;
      }
    });
    return bestValue;
  }
}

class NoteValue {
  final String label;
  final double beats;

  NoteValue._(this.label, this.beats);

  static final whole        = NoteValue._('whole', 4.0);
  static final half         = NoteValue._('half', 2.0);
  static final dottedQuarter= NoteValue._('dottedQuarter', 1.5);
  static final quarter      = NoteValue._('quarter', 1.0);
  static final dottedEighth = NoteValue._('dottedEighth', 0.75);
  static final eighth       = NoteValue._('eighth', 0.5);
  static final sixteenth    = NoteValue._('sixteenth', 0.25);

  bool get isHollowHead => label == 'whole' || label == 'half';
  bool get isDotted => label.startsWith('dotted');

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
}