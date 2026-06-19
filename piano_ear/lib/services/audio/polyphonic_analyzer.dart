import 'dart:math' as math;

import '../../core/constants/app_constants.dart';
import '../../core/utils/music_math.dart';
import 'fft.dart';

/// Estima qué notas MIDI están sonando simultáneamente a partir del
/// espectro de magnitud de una ventana de audio (FFT + supresión de
/// armónicos). Funciona bien para acordes de 2-4 notas tocados con
/// claridad. Para más precisión se puede sustituir por un modelo TFLite.
class PolyphonicAnalyzer {
  final double sampleRate;

  PolyphonicAnalyzer({required this.sampleRate});

  List<int> detectActivePitches(
    List<double> windowedSamples, {
    int maxNotes = 6,
  }) {
    final spectrum = FFT.magnitudeSpectrum(windowedSamples);
    final n = (spectrum.length - 1) * 2;
    final binHz = sampleRate / n;

    final maxMag = spectrum.fold<double>(0, math.max);
    if (maxMag <= 1e-6) return [];
    final relativeThreshold = maxMag * 0.06;

    final peakBins = <int>[];
    for (int i = 2; i < spectrum.length - 1; i++) {
      final freq = i * binHz;
      if (freq < AppConstants.minFrequencyHz ||
          freq > AppConstants.maxFrequencyHz) continue;
      if (spectrum[i] > relativeThreshold &&
          spectrum[i] >= spectrum[i - 1] &&
          spectrum[i] >= spectrum[i + 1]) {
        peakBins.add(i);
      }
    }
    if (peakBins.isEmpty) return [];

    peakBins.sort((a, b) => spectrum[b].compareTo(spectrum[a]));

    final acceptedFreqs = <double>[];
    final acceptedMidi = <int>[];

    for (final bin in peakBins) {
      if (acceptedMidi.length >= maxNotes) break;
      final freq = bin * binHz;

      bool isHarmonic = false;
      for (final f0 in acceptedFreqs) {
        final ratio = freq / f0;
        final nearestH = ratio.round();
        if (nearestH >= 2 &&
            nearestH <= 8 &&
            (ratio - nearestH).abs() < 0.04 * nearestH) {
          isHarmonic = true;
          break;
        }
      }
      if (isHarmonic) continue;

      final midi = MusicMath.frequencyToNearestMidi(freq);
      if (acceptedMidi.contains(midi)) continue;

      acceptedFreqs.add(freq);
      acceptedMidi.add(midi);
    }

    acceptedMidi.sort();
    return acceptedMidi;
  }
}
