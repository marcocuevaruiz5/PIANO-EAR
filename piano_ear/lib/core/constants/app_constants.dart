/// Parámetros del pipeline de captura y análisis de audio.
class AppConstants {
  AppConstants._();

  static const int sampleRate = 44100;

  /// Tamaño de la ventana de análisis (potencia de 2, ~46 ms a 44.1kHz).
  static const int analysisFrameSize = 2048;

  /// Salto entre ventanas consecutivas (hop size), ~11.6 ms -> permite
  /// resolución temporal razonable para detectar onsets de notas de piano.
  static const int hopSize = 512;

  /// Umbral YIN estándar (Cheveigné & Kawahara, 2002).
  static const double yinThreshold = 0.12;

  /// Rango de frecuencias válidas para piano (A0 ≈ 27.5 Hz, C8 ≈ 4186 Hz).
  static const double minFrequencyHz = 25.0;
  static const double maxFrequencyHz = 4400.0;

  /// Umbral relativo de energía (RMS) bajo el cual se considera silencio.
  static const double silenceRmsThreshold = 0.012;

  /// Caída relativa de energía de un parcial para considerar que la nota
  /// terminó (offset detection simplificado por envolvente).
  static const double noteOffDecayRatio = 0.25;

  static const String dbName = 'piano_ear.db';
  static const int dbVersion = 1;
}
