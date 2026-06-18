import 'dart:math' as math;

/// Implementación del algoritmo YIN (de Cheveigné & Kawahara, 2002) para
/// estimación de tono (pitch tracking) monofónico. YIN es el algoritmo
/// clásico, ligero en CPU, ideal para correr en el dispositivo en tiempo
/// real (a diferencia de CREPE, que es una red neuronal pensada para
/// correr off-line/con aceleración — ver nota en README sobre por qué
/// este proyecto usa YIN como motor principal).
///
/// Es muy preciso para una sola nota sonando. Para acordes (varias notas
/// simultáneas) se complementa con [PolyphonicAnalyzer], que usa la FFT
/// y "Harmonic Product Spectrum" para estimar varias fundamentales a la
/// vez.
class YinPitchDetector {
  final double sampleRate;
  final double threshold;

  YinPitchDetector({
    required this.sampleRate,
    this.threshold = 0.12,
  });

  /// Devuelve la frecuencia fundamental estimada en Hz, o `null` si no se
  /// encontró un período suficientemente periódico (silencio / ruido).
  double? detectPitch(List<double> buffer) {
    final n = buffer.length;
    final maxTau = n ~/ 2;
    final diff = List<double>.filled(maxTau, 0.0);
    final cmnd = List<double>.filled(maxTau, 0.0);

    // 1. Función de diferencia (difference function).
    for (int tau = 0; tau < maxTau; tau++) {
      double sum = 0.0;
      for (int i = 0; i < maxTau; i++) {
        final delta = buffer[i] - buffer[i + tau];
        sum += delta * delta;
      }
      diff[tau] = sum;
    }

    // 2. Función de diferencia media normalizada acumulada (CMND).
    cmnd[0] = 1.0;
    double runningSum = 0.0;
    for (int tau = 1; tau < maxTau; tau++) {
      runningSum += diff[tau];
      cmnd[tau] = runningSum == 0 ? 1.0 : diff[tau] * tau / runningSum;
    }

    // 3. Umbral absoluto: primer mínimo local por debajo de [threshold].
    int? tauEstimate;
    for (int tau = 2; tau < maxTau - 1; tau++) {
      if (cmnd[tau] < threshold) {
        // Buscar el mínimo local real (puede seguir bajando).
        int localTau = tau;
        while (localTau + 1 < maxTau && cmnd[localTau + 1] < cmnd[localTau]) {
          localTau++;
        }
        tauEstimate = localTau;
        break;
      }
    }
    if (tauEstimate == null) return null;

    // 4. Interpolación parabólica alrededor de tauEstimate para refinar.
    final betterTau = _parabolicInterpolation(cmnd, tauEstimate);
    if (betterTau <= 0) return null;

    return sampleRate / betterTau;
  }

  double _parabolicInterpolation(List<double> arr, int pos) {
    final x0 = pos < 1 ? pos : pos - 1;
    final x2 = pos + 1 < arr.length ? pos + 1 : pos;
    if (x0 == pos || x2 == pos) return pos.toDouble();

    final s0 = arr[x0];
    final s1 = arr[pos];
    final s2 = arr[x2];
    final denom = (s2 + s0 - 2 * s1);
    if (denom == 0) return pos.toDouble();
    return pos + (s0 - s2) / (2 * denom);
  }

  /// RMS (root-mean-square) de un buffer: medida simple de energía, usada
  /// para detección de onset/offset y como base de la "velocity" MIDI.
  static double rms(List<double> buffer) {
    if (buffer.isEmpty) return 0.0;
    double sum = 0.0;
    for (final s in buffer) {
      sum += s * s;
    }
    return math.sqrt(sum / buffer.length);
  }
}
