import 'dart:math' as math;

/// Implementación mínima de una FFT radix-2 (Cooley-Tukey) en Dart puro.
/// Se evita depender de un paquete externo para mantener el motor de
/// análisis autocontenido y fácil de auditar/ajustar.
///
/// Requiere que `real.length` sea potencia de 2 — usar [nextPowerOfTwo]
/// y rellenar con ceros (zero-padding) si es necesario.
class FFT {
  FFT._();

  static int nextPowerOfTwo(int n) {
    int p = 1;
    while (p < n) {
      p <<= 1;
    }
    return p;
  }

  /// Transformada in-place. `real`/`imag` deben tener la misma longitud,
  /// potencia de 2. Al terminar, `real`/`imag` contienen el resultado.
  static void transform(List<double> real, List<double> imag) {
    final n = real.length;
    if (n == 0) return;
    assert(n & (n - 1) == 0, 'FFT.transform requiere longitud potencia de 2');

    // Bit-reversal permutation.
    for (int i = 1, j = 0; i < n; i++) {
      int bit = n >> 1;
      for (; j & bit != 0; bit >>= 1) {
        j ^= bit;
      }
      j ^= bit;
      if (i < j) {
        final tr = real[i];
        real[i] = real[j];
        real[j] = tr;
        final ti = imag[i];
        imag[i] = imag[j];
        imag[j] = ti;
      }
    }

    for (int len = 2; len <= n; len <<= 1) {
      final ang = -2 * math.pi / len;
      final wReal = math.cos(ang);
      final wImag = math.sin(ang);
      for (int i = 0; i < n; i += len) {
        double curReal = 1.0;
        double curImag = 0.0;
        for (int j = 0; j < len ~/ 2; j++) {
          final uReal = real[i + j];
          final uImag = imag[i + j];
          final vReal = real[i + j + len ~/ 2] * curReal -
              imag[i + j + len ~/ 2] * curImag;
          final vImag = real[i + j + len ~/ 2] * curImag +
              imag[i + j + len ~/ 2] * curReal;

          real[i + j] = uReal + vReal;
          imag[i + j] = uImag + vImag;
          real[i + j + len ~/ 2] = uReal - vReal;
          imag[i + j + len ~/ 2] = uImag - vImag;

          final nextReal = curReal * wReal - curImag * wImag;
          final nextImag = curReal * wImag + curImag * wReal;
          curReal = nextReal;
          curImag = nextImag;
        }
      }
    }
  }

  /// Calcula el espectro de magnitud de una señal real (ventaneada
  /// previamente por el llamador). Devuelve `n/2 + 1` bins útiles.
  static List<double> magnitudeSpectrum(List<double> samples) {
    final n = nextPowerOfTwo(samples.length);
    final real = List<double>.filled(n, 0.0);
    final imag = List<double>.filled(n, 0.0);
    for (int i = 0; i < samples.length; i++) {
      real[i] = samples[i];
    }
    transform(real, imag);
    final half = n ~/ 2;
    return List<double>.generate(
      half + 1,
      (i) => math.sqrt(real[i] * real[i] + imag[i] * imag[i]),
    );
  }

  /// Ventana de Hann, reduce fugas espectrales antes de la FFT.
  static List<double> hannWindow(List<double> samples) {
    final n = samples.length;
    return List<double>.generate(n, (i) {
      final w = 0.5 - 0.5 * math.cos(2 * math.pi * i / (n - 1));
      return samples[i] * w;
    });
  }
}
