import 'package:flutter/material.dart';
import '../../core/constants/piano_constants.dart';
import 'learning_provider.dart';

/// Dibuja las barras de notas que caen (estilo Synthesia/Piano Hero).
/// Cada barra se alinea horizontalmente con la tecla del piano correspondiente.
class FallingNotesPainter extends CustomPainter {
  final List<FallingNote> fallingNotes;
  final ColorScheme scheme;

  const FallingNotesPainter({
    required this.fallingNotes,
    required this.scheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final whites = PianoConstants.whiteKeys;
    final wKeyWidth = size.width / whites.length;

    for (final fn in fallingNotes) {
      if (fn.y < -0.05 || fn.y > 1.1) continue;
      final x = _midiToX(fn.midi, whites, wKeyWidth, size);
      final barW = PianoConstants.isBlackKey(fn.midi)
          ? wKeyWidth * 0.55
          : wKeyWidth * 0.82;

      final barH = size.height * 0.12;
      final top = fn.y * size.height - barH;

      final Color color;
      if (fn.hit) {
        color = Colors.white.withOpacity(0.15);
      } else if (fn.y >= 0.85) {
        color = Colors.orange.withOpacity(0.9);
      } else {
        color = PianoConstants.isBlackKey(fn.midi)
            ? scheme.primary.withOpacity(0.85)
            : scheme.primary.withOpacity(0.7);
      }

      final rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barW / 2, top, barW, barH),
        const Radius.circular(4),
      );
      canvas.drawRRect(rRect, Paint()..color = color);

      // Glow alrededor de la barra
      if (!fn.hit) {
        canvas.drawRRect(
          rRect,
          Paint()
            ..color = color.withOpacity(0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }
  }

  double _midiToX(
      int midi, List<int> whites, double wKeyWidth, Size size) {
    if (PianoConstants.isWhiteKey(midi)) {
      final idx = whites.indexOf(midi);
      return idx * wKeyWidth + wKeyWidth / 2;
    } else {
      // Tecla negra: entre las dos blancas adyacentes.
      final leftWhite = midi - 1;
      final idx = whites.indexOf(leftWhite);
      return idx * wKeyWidth + wKeyWidth;
    }
  }

  @override
  bool shouldRepaint(FallingNotesPainter old) => true;
}