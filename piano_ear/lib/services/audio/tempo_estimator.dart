/// Estimación de tempo (BPM) a partir de la lista de tiempos de onset
/// detectados, usando autocorrelación de inter-onset intervals (IOI).
///
/// El método es robusto para tempos entre 40 y 240 BPM. Para grabaciones
/// cortas (< 4 compases) la estimación puede tener ±5 BPM de error;
/// en ese caso se devuelve el valor por defecto de 120 BPM.
class TempoEstimator {
  static const double _defaultBpm = 120.0;
  static const double _minBpm = 40.0;
  static const double _maxBpm = 240.0;

  static double estimate(List<int> onsetTimesMs) {
    if (onsetTimesMs.length < 4) return _defaultBpm;

    final sorted = [...onsetTimesMs]..sort();
    final iois = <int>[];
    for (int i = 1; i < sorted.length; i++) {
      final d = sorted[i] - sorted[i - 1];
      if (d > 50 && d < 3000) iois.add(d);
    }
    if (iois.isEmpty) return _defaultBpm;

    // Histograma de IOIs cuantizado a 10 ms de resolución.
    final hist = <int, int>{};
    for (final d in iois) {
      final bucket = (d / 10).round() * 10;
      hist[bucket] = (hist[bucket] ?? 0) + 1;
    }

    // Buscamos el IOI modal y sus submúltiplos / múltiplos.
    final sortedBuckets = hist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    double bestBpm = _defaultBpm;
    int bestScore = 0;

    for (final entry in sortedBuckets.take(5)) {
      final baseMs = entry.key.toDouble();
      for (final multiplier in [1.0, 0.5, 2.0, 1.5, 0.667]) {
        final beatMs = baseMs * multiplier;
        final bpm = 60000.0 / beatMs;
        if (bpm < _minBpm || bpm > _maxBpm) continue;

        int score = 0;
        for (final ioi in iois) {
          final ratio = ioi / beatMs;
          final nearest = ratio.round();
          if (nearest >= 1 && nearest <= 8 && (ratio - nearest).abs() < 0.1) {
            score++;
          }
        }
        if (score > bestScore) {
          bestScore = score;
          bestBpm = bpm;
        }
      }
    }

    return bestBpm;
  }
}
