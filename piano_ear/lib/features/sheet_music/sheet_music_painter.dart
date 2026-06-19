import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/piano_constants.dart';
import '../../data/models/note_event.dart';

/// Dibuja una partitura musical completa a partir de una lista de NoteEvent.
/// Usa CustomPainter para renderizar en Canvas: pentagrama, clave de sol,
/// cabezas de nota, plicas, lineas de ledger y barras de compas.
class SheetMusicPainter extends CustomPainter {
  final List<NoteEvent> notes;
  final double tempoBpm;
  final int timeSignatureNum;
  final int timeSignatureDen;
  final ColorScheme scheme;
  final double scale;

  static const double _sl = 10.0;   // staff line spacing
  static const double _ml = 64.0;   // margin left
  static const double _mt = 60.0;   // margin top
  static const int _spr = 16;       // steps per row (sixteenth notes)

  SheetMusicPainter({
    required this.notes,
    required this.tempoBpm,
    required this.timeSignatureNum,
    required this.timeSignatureDen,
    required this.scheme,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);
    final w = size.width / scale;

    final inkP = Paint()
      ..color = scheme.onSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final fillP = Paint()
      ..color = scheme.onSurface
      ..style = PaintingStyle.fill;

    final beatMs = 60000.0 / tempoBpm;
    final sixteenthMs = beatMs / 4;
    final stepsPerBar = timeSignatureNum * 4;

    // Convertir notas a grid de semicorcheas
    final renders = notes.map((n) {
      final step = (n.startTimeMs / sixteenthMs).round();
      final dur = math.max(1, (n.durationMs / sixteenthMs).round());
      return _NR(note: n, step: step, dur: dur);
    }).toList();

    if (renders.isEmpty) {
      _drawEmpty(canvas, scheme);
      canvas.restore();
      return;
    }

    final totalSteps = renders.map((r) => r.step + r.dur).reduce(math.max);
    final rows = (totalSteps / _spr).ceil().clamp(1, 999);
    final stepW = (w - _ml - 24) / _spr;

    for (int row = 0; row < rows; row++) {
      final yBase = _mt + row * (_sl * 8 + 40);
      _drawStaff(canvas, yBase, w - _ml - 24, inkP);
      _drawClef(canvas, yBase, scheme);
      _drawBarLines(canvas, yBase, stepsPerBar, stepW, row, totalSteps, inkP);
    }

    for (final nr in renders) {
      final row = nr.step ~/ _spr;
      final col = nr.step % _spr;
      final yBase = _mt + row * (_sl * 8 + 40);
      final x = _ml + col * stepW + stepW / 2;
      _paintNote(canvas, nr, x, yBase, inkP, fillP, scheme);
    }

    canvas.restore();
  }

  void _drawStaff(Canvas canvas, double yBase, double width, Paint p) {
    for (int l = 0; l < 5; l++) {
      final y = yBase + l * _sl;
      canvas.drawLine(Offset(_ml - 4, y), Offset(_ml + width, y), p);
    }
  }

  void _drawClef(Canvas canvas, double yBase, ColorScheme scheme) {
    final tp = TextPainter(
      text: TextSpan(
        text: '\u{1D11E}',
        style: TextStyle(fontSize: 38, color: scheme.onSurface),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(6, yBase - 6));
  }

  void _drawBarLines(Canvas canvas, double yBase, int stepsPerBar,
      double stepW, int row, int totalSteps, Paint p) {
    final stepsInRow = math.min(_spr, totalSteps - row * _spr);
    for (int s = stepsPerBar; s <= stepsInRow; s += stepsPerBar) {
      final x = _ml + s * stepW;
      canvas.drawLine(
          Offset(x, yBase), Offset(x, yBase + 4 * _sl), p);
    }
  }

  double _midiToY(int midi, double yBase) {
    // B4 = MIDI 71 -> linea 3 del pentagrama (treble clef)
    const scaleMap = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6];
    final fromB4 = midi - 71;
    int oct = fromB4 ~/ 12;
    int rem = fromB4 % 12;
    if (rem < 0) { rem += 12; oct -= 1; }
    final dia = scaleMap[rem] + oct * 7;
    return (yBase + 2 * _sl) - dia * (_sl / 2);
  }

  void _paintNote(Canvas canvas, _NR nr, double x, double yBase,
      Paint inkP, Paint fillP, ColorScheme scheme) {
    final y = _midiToY(nr.note.midi, yBase);
    final r = _sl * 0.52;
    final hollow = nr.dur >= 8;

    final head = Rect.fromCenter(
        center: Offset(x, y), width: r * 2.2, height: r * 1.5);
    if (hollow) {
      canvas.drawOval(head, inkP..strokeWidth = 1.2);
    } else {
      canvas.drawOval(head, fillP);
    }

    // Plica
    if (nr.dur < 16) {
      final up = nr.note.midi < 71;
      final sx = up ? x + r : x - r;
      final sy = up ? y - _sl * 3.5 : y + _sl * 3.5;
      canvas.drawLine(Offset(sx, y), Offset(sx, sy), inkP..strokeWidth = 1.2);
    }

    // Sostenido
    final pc = nr.note.midi % 12;
    if (PianoConstants.blackKeyPitchClasses.contains(pc)) {
      final tp = TextPainter(
        text: TextSpan(
            text: '#',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface)),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x - r * 2.5, y - 6));
    }

    // Lineas de ledger
    final top = yBase;
    final bot = yBase + 4 * _sl;
    final ledgerP = inkP..strokeWidth = 1.0;
    if (y > bot + _sl / 2) {
      for (double ly = bot + _sl; ly <= y + _sl / 2; ly += _sl) {
        canvas.drawLine(Offset(x - r * 1.8, ly), Offset(x + r * 1.8, ly), ledgerP);
      }
    }
    if (y < top - _sl / 2) {
      for (double ly = top - _sl; ly >= y - _sl / 2; ly -= _sl) {
        canvas.drawLine(Offset(x - r * 1.8, ly), Offset(x + r * 1.8, ly), ledgerP);
      }
    }
  }

  void _drawEmpty(Canvas canvas, ColorScheme scheme) {
    final tp = TextPainter(
      text: TextSpan(
          text: 'Sin notas para mostrar',
          style: TextStyle(color: scheme.onSurface.withOpacity(0.4), fontSize: 16)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, const Offset(32, 40));
  }

  @override
  bool shouldRepaint(SheetMusicPainter old) =>
      old.notes != notes || old.scale != scale;
}

class _NR {
  final NoteEvent note;
  final int step;
  final int dur;
  _NR({required this.note, required this.step, required this.dur});
}