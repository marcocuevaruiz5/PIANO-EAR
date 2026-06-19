import 'package:flutter/material.dart';
import '../../core/constants/piano_constants.dart';

/// Dibuja el teclado completo de 88 teclas con resaltado de notas
/// esperadas (naranja/acento) y notas escuchadas (verde).
class Keyboard88Painter extends CustomPainter {
  final Set<int> expectedMidi;
  final Set<int> heardMidi;
  final ColorScheme scheme;

  const Keyboard88Painter({
    required this.expectedMidi,
    required this.heardMidi,
    required this.scheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final whites = PianoConstants.whiteKeys;
    final wWidth = size.width / whites.length;
    final wHeight = size.height;
    final bHeight = wHeight * 0.62;

    // ── Teclas blancas ────────────────────────────────────────────────────
    for (int i = 0; i < whites.length; i++) {
      final midi = whites[i];
      final rect = Rect.fromLTWH(i * wWidth, 0, wWidth - 1, wHeight);

      Color fill;
      if (heardMidi.contains(midi)) {
        fill = const Color(0xFF22C55E); // verde = tocada
      } else if (expectedMidi.contains(midi)) {
        fill = Colors.orange.shade300;
      } else {
        fill = Colors.white;
      }

      canvas.drawRect(rect, Paint()..color = fill);
      canvas.drawRect(
          rect,
          Paint()
            ..color = Colors.black26
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5);
    }

    // ── Teclas negras ─────────────────────────────────────────────────────
    for (int i = 0; i < whites.length - 1; i++) {
      final wMidi = whites[i];
      final bMidi = wMidi + 1;
      if (!PianoConstants.isBlackKey(bMidi)) continue;

      final bx = (i + 1) * wWidth - wWidth * 0.3;
      final rect = Rect.fromLTWH(bx, 0, wWidth * 0.6, bHeight);

      Color fill;
      if (heardMidi.contains(bMidi)) {
        fill = const Color(0xFF16A34A);
      } else if (expectedMidi.contains(bMidi)) {
        fill = Colors.orange;
      } else {
        fill = const Color(0xFF1A1A1A);
      }

      canvas.drawRect(rect, Paint()..color = fill);
      // Borde inferior redondeado
      canvas.drawRRect(
          RRect.fromRectAndCorners(rect,
              bottomLeft: const Radius.circular(3),
              bottomRight: const Radius.circular(3)),
          Paint()
            ..color = Colors.black45
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5);
    }
  }

  @override
  bool shouldRepaint(Keyboard88Painter old) =>
      old.expectedMidi != expectedMidi || old.heardMidi != heardMidi;
}