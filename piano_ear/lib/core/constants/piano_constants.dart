/// Constantes relacionadas con el teclado de piano de 88 teclas (A0..C8).
///
/// Usamos números MIDI como representación canónica de cada tecla:
///   A0 = 21 ... C8 = 108
class PianoConstants {
  PianoConstants._();

  static const int lowestMidi = 21; // A0
  static const int highestMidi = 108; // C8
  static const int totalKeys = highestMidi - lowestMidi + 1; // 88

  /// Nombres de nota en notación con sostenidos, índice 0 = C.
  static const List<String> noteNamesSharp = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  /// Posiciones (0..11 dentro de la octava) que corresponden a tecla negra.
  static const Set<int> blackKeyPitchClasses = {1, 3, 6, 8, 10};

  static bool isBlackKey(int midi) {
    final pc = midi % 12;
    return blackKeyPitchClasses.contains(pc);
  }

  static bool isWhiteKey(int midi) => !isBlackKey(midi);

  /// Devuelve el nombre de nota con octava, ej. 60 -> "C4".
  static String midiToName(int midi) {
    final pc = midi % 12;
    final octave = (midi ~/ 12) - 1;
    return '${noteNamesSharp[pc]}$octave';
  }

  /// Lista de todas las teclas blancas en orden ascendente (para layout).
  static List<int> get whiteKeys =>
      List.generate(totalKeys, (i) => lowestMidi + i)
          .where(isWhiteKey)
          .toList();

  static List<int> get blackKeys =>
      List.generate(totalKeys, (i) => lowestMidi + i)
          .where(isBlackKey)
          .toList();
}
