import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/piano_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/song.dart';
import 'falling_notes_painter.dart';
import 'keyboard_88_painter.dart';
import 'learning_provider.dart';

class LearningScreen extends StatelessWidget {
  final Song song;
  const LearningScreen({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LearningProvider(song: song),
      child: const _LearningView(),
    );
  }
}

class _LearningView extends StatelessWidget {
  const _LearningView();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<LearningProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(prov.song.title,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          if (prov.status != LearningStatus.idle)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              onPressed: () => prov.reset(),
            ),
        ],
      ),
      body: Column(children: [
        // ── Barra de estadisticas ───────────────────────────────────────────
        _StatsBar(prov: prov),

        // ── Zona de lluvia de notas (ocupa el mayor espacio) ───────────────
        Expanded(
          flex: 5,
          child: Stack(children: [
            // Fondo oscuro con efecto de brillo
            Container(color: const Color(0xFF0D0D14)),

            // Lluvia de notas
            CustomPaint(
              painter: FallingNotesPainter(
                fallingNotes: prov.fallingNotes,
                scheme: scheme,
              ),
              child: const SizedBox.expand(),
            ),

            // Banner de estado (PAUSA / CORRECTO!)
            if (prov.status == LearningStatus.paused)
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Text('Toca la nota resaltada',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
              ),
            if (prov.status == LearningStatus.finished)
              _FinishedOverlay(prov: prov),
          ]),
        ),

        // ── Teclado de 88 teclas ────────────────────────────────────────────
        Expanded(
          flex: 2,
          child: CustomPaint(
            painter: Keyboard88Painter(
              expectedMidi: prov.expectedMidi,
              heardMidi: prov.heardMidi,
              scheme: scheme,
            ),
            child: const SizedBox.expand(),
          ),
        ),

        // ── Boton de inicio ─────────────────────────────────────────────────
        if (prov.status == LearningStatus.idle)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Iniciar practica'),
                onPressed: () => prov.start(),
                style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50)),
              ),
            ),
          ),
      ]),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final LearningProvider prov;
  const _StatsBar({required this.prov});

  @override
  Widget build(BuildContext context) {
    final pct = prov.progressPercent;
    final accuracy = prov.correctCount + prov.wrongCount == 0
        ? 100.0
        : prov.correctCount /
            (prov.correctCount + prov.wrongCount) *
            100;

    return Container(
      color: const Color(0xFF15151E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        // Barra de progreso
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white12,
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFF6750FF)),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${accuracy.round()}%',
          style: TextStyle(
              color: accuracy >= 80 ? AppTheme.success : Colors.orange,
              fontWeight: FontWeight.w700,
              fontSize: 15),
        ),
        const SizedBox(width: 8),
        Text(
          '${prov.correctCount}✓  ${prov.wrongCount}✗',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ]),
    );
  }
}

class _FinishedOverlay extends StatelessWidget {
  final LearningProvider prov;
  const _FinishedOverlay({required this.prov});

  @override
  Widget build(BuildContext context) {
    final total = prov.correctCount + prov.wrongCount;
    final pct = total == 0 ? 100 : (prov.correctCount / total * 100).round();

    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(pct >= 90 ? '🎉' : pct >= 70 ? '👍' : '💪',
              style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('$pct% de precision',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('${prov.correctCount} correctas  •  ${prov.wrongCount} errores',
              style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Volver a intentar'),
            onPressed: () => prov.reset(),
          ),
        ]),
      ),
    );
  }
}