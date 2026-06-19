import 'package:flutter/material.dart';
import '../../data/models/song.dart';
import '../learning/learning_screen.dart';
import 'sheet_music_painter.dart';

class SheetMusicScreen extends StatefulWidget {
  final Song song;
  const SheetMusicScreen({super.key, required this.song});

  @override
  State<SheetMusicScreen> createState() => _SheetMusicScreenState();
}

class _SheetMusicScreenState extends State<SheetMusicScreen> {
  double _scale = 1.0;
  final TransformationController _transformCtrl = TransformationController();

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final scheme = Theme.of(context).colorScheme;

    // Estimar alto necesario para la partitura
    const rowHeight = 140.0;
    const stepsPerRow = 16;
    final beatMs = 60000.0 / song.tempoBpm;
    final sixteenthMs = beatMs / 4;
    final totalSteps = song.notes.isEmpty
        ? stepsPerRow
        : song.notes
            .map((n) =>
                (n.startTimeMs / sixteenthMs).round() +
                ((n.durationMs / sixteenthMs).round()).clamp(1, 9999))
            .reduce((a, b) => a > b ? a : b);
    final rows = (totalSteps / stepsPerRow).ceil();
    final canvasHeight = rows * rowHeight + 80.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.school_rounded),
            tooltip: 'Modo aprendizaje',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => LearningScreen(song: song))),
          ),
          PopupMenuButton<double>(
            icon: const Icon(Icons.zoom_in_rounded),
            onSelected: (v) => setState(() => _scale = v),
            itemBuilder: (_) => [0.75, 1.0, 1.25, 1.5, 2.0]
                .map((v) => PopupMenuItem(
                    value: v, child: Text('${(v * 100).round()}%')))
                .toList(),
          ),
        ],
      ),
      body: Column(children: [
        // Metadatos
        Container(
          color: scheme.surfaceContainerHigh,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(children: [
            _Chip(label: '${song.tempoBpm.round()} BPM'),
            const SizedBox(width: 8),
            _Chip(label: '${song.timeSignatureNumerator}/${song.timeSignatureDenominator}'),
            const SizedBox(width: 8),
            _Chip(label: '${song.notes.length} notas'),
            const SizedBox(width: 8),
            _Chip(label: song.durationLabel),
          ]),
        ),
        // Partitura con zoom y scroll
        Expanded(
          child: InteractiveViewer(
            transformationController: _transformCtrl,
            minScale: 0.5,
            maxScale: 4.0,
            child: SizedBox(
              width: double.infinity,
              height: canvasHeight * _scale,
              child: CustomPaint(
                painter: SheetMusicPainter(
                  notes: song.notes,
                  tempoBpm: song.tempoBpm,
                  timeSignatureNum: song.timeSignatureNumerator,
                  timeSignatureDen: song.timeSignatureDenominator,
                  scheme: scheme,
                  scale: _scale,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary)),
    );
  }
}