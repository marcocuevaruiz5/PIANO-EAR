import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/piano_constants.dart';
import '../../core/theme/app_theme.dart';
import '../sheet_music/sheet_music_screen.dart';
import 'recording_provider.dart';

class RecordingScreen extends StatelessWidget {
  const RecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecordingProvider(),
      child: const _RecordingView(),
    );
  }
}

class _RecordingView extends StatefulWidget {
  const _RecordingView();

  @override
  State<_RecordingView> createState() => _RecordingViewState();
}

class _RecordingViewState extends State<_RecordingView> {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RecordingProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grabar pieza'),
        leading: BackButton(onPressed: () {
          if (prov.isRecording) {
            prov.stopAndSave('Sin titulo ${DateTime.now().second}');
          }
          Navigator.pop(context);
        }),
      ),
      body: Column(children: [
        // ── Nivel de audio (VU meter) ──────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: _VuMeter(rms: prov.rms),
        ),

        // ── Teclado mini con teclas activas resaltadas ──────
        SizedBox(
          height: 100,
          child: _MiniKeyboard(activeMidi: prov.activeMidi),
        ),

        // ── Notas detectadas ────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notas detectadas: ${prov.liveNotes.length}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Expanded(
                  child: prov.liveNotes.isEmpty
                      ? Center(
                          child: Text('Toca el piano para comenzar...',
                              style: TextStyle(
                                  color: scheme.onSurface.withOpacity(0.4))))
                      : ListView.builder(
                          reverse: true,
                          itemCount: prov.liveNotes.length,
                          itemBuilder: (_, i) {
                            final n = prov.liveNotes[prov.liveNotes.length - 1 - i];
                            return Text(
                              '${PianoConstants.midiToName(n.midi)}  '
                              '${(n.durationMs / 1000).toStringAsFixed(2)}s  '
                              'vel:${n.velocity}',
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 12),
                            );
                          }),
                ),
              ],
            ),
          ),
        ),

        // ── Controles ───────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _Controls(prov: prov),
          ),
        ),
      ]),
    );
  }
}

class _Controls extends StatelessWidget {
  final RecordingProvider prov;
  const _Controls({required this.prov});

  @override
  Widget build(BuildContext context) {
    switch (prov.status) {
      case RecordingStatus.idle:
        return FilledButton.icon(
          icon: const Icon(Icons.mic_rounded),
          label: const Text('Iniciar grabacion'),
          onPressed: () => prov.startRecording(),
        );

      case RecordingStatus.recording:
        return FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Detener y guardar'),
          onPressed: () => _showSaveDialog(context, prov),
        );

      case RecordingStatus.processing:
        return const Center(child: CircularProgressIndicator());

      case RecordingStatus.done:
        return Column(children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 40),
          const SizedBox(height: 8),
          Text('Pieza guardada',
              style: TextStyle(
                  color: AppTheme.success, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            OutlinedButton(
                onPressed: () => prov.reset(),
                child: const Text('Grabar otra')),
            const SizedBox(width: 12),
            if (prov.lastSavedSong != null)
              FilledButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            SheetMusicScreen(song: prov.lastSavedSong!))),
                child: const Text('Ver partitura'),
              ),
          ]),
        ]);
    }
  }

  void _showSaveDialog(BuildContext context, RecordingProvider prov) {
    final ctrl = TextEditingController(
        text: 'Pieza ${DateTime.now().day}/${DateTime.now().month}');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Guardar grabacion'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nombre de la pieza'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                Navigator.pop(context);
                prov.stopAndSave(ctrl.text.trim().isEmpty ? 'Sin titulo' : ctrl.text.trim());
              },
              child: const Text('Guardar')),
        ],
      ),
    );
  }
}

// ── VU Meter ─────────────────────────────────────────────────────────────────

class _VuMeter extends StatelessWidget {
  final double rms;
  const _VuMeter({required this.rms});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final level = (rms * 4).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: LinearProgressIndicator(
          value: level,
          backgroundColor: scheme.surfaceContainerHigh,
          valueColor: AlwaysStoppedAnimation(
            level > 0.75 ? AppTheme.error : scheme.primary,
          ),
        ),
      ),
    );
  }
}

// ── Mini Keyboard ─────────────────────────────────────────────────────────────

class _MiniKeyboard extends StatelessWidget {
  final Set<int> activeMidi;
  const _MiniKeyboard({required this.activeMidi});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniKeyboardPainter(
        activeMidi: activeMidi,
        scheme: Theme.of(context).colorScheme,
      ),
    );
  }
}

class _MiniKeyboardPainter extends CustomPainter {
  final Set<int> activeMidi;
  final ColorScheme scheme;

  _MiniKeyboardPainter({required this.activeMidi, required this.scheme});

  @override
  void paint(Canvas canvas, Size size) {
    final whites = PianoConstants.whiteKeys;
    final wWidth = size.width / whites.length;
    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = scheme.outlineVariant
      ..strokeWidth = 0.5;

    for (int i = 0; i < whites.length; i++) {
      final midi = whites[i];
      paint.color = activeMidi.contains(midi) ? scheme.primary : Colors.white;
      final rect = Rect.fromLTWH(i * wWidth, 0, wWidth - 0.5, size.height);
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);
    }

    // Black keys
    for (int i = 0; i < whites.length - 1; i++) {
      final wMidi = whites[i];
      final bCandidate = wMidi + 1;
      if (!PianoConstants.isBlackKey(bCandidate)) continue;
      final bx = (i + 1) * wWidth - wWidth * 0.3;
      paint.color = activeMidi.contains(bCandidate)
          ? scheme.primary
          : const Color(0xFF1A1A1A);
      canvas.drawRect(
          Rect.fromLTWH(bx, 0, wWidth * 0.6, size.height * 0.62), paint);
    }
  }

  @override
  bool shouldRepaint(_MiniKeyboardPainter old) => old.activeMidi != activeMidi;
}