import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/song.dart';
import '../learning/learning_screen.dart';
import '../sheet_music/sheet_music_screen.dart';
import 'library_provider.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LibraryProvider()..load(),
      child: const _LibraryView(),
    );
  }
}

class _LibraryView extends StatelessWidget {
  const _LibraryView();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<LibraryProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca')),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.songs.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.music_off_rounded,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.2)),
                    const SizedBox(height: 16),
                    const Text('Aun no tienes grabaciones.',
                        style: TextStyle(fontSize: 16)),
                  ]),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: prov.songs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _SongTile(song: prov.songs[i], prov: prov),
                ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final Song song;
  final LibraryProvider prov;
  const _SongTile({required this.song, required this.prov});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(song.createdAt);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.music_note_rounded, color: scheme.primary),
        ),
        title: Text(song.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '$dateStr  •  ${song.durationLabel}  •  ${song.tempoBpm.round()} BPM',
            style: TextStyle(
                fontSize: 12, color: scheme.onSurface.withOpacity(0.55))),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => _handleMenu(context, v),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'sheet', child: Text('Ver partitura')),
            PopupMenuItem(value: 'learn', child: Text('Modo aprendizaje')),
            PopupMenuItem(value: 'rename', child: Text('Renombrar')),
            PopupMenuItem(
                value: 'delete',
                child: Text('Eliminar', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  void _handleMenu(BuildContext context, String action) {
    switch (action) {
      case 'sheet':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => SheetMusicScreen(song: song)));
        break;
      case 'learn':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => LearningScreen(song: song)));
        break;
      case 'rename':
        _showRenameDialog(context);
        break;
      case 'delete':
        _showDeleteDialog(context);
        break;
    }
  }

  void _showRenameDialog(BuildContext context) {
    final ctrl = TextEditingController(text: song.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Renombrar pieza'),
        content: TextField(controller: ctrl, autofocus: true,
            decoration: const InputDecoration(labelText: 'Nuevo nombre')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                Navigator.pop(context);
                if (ctrl.text.trim().isNotEmpty) {
                  prov.rename(song.id, ctrl.text.trim());
                }
              },
              child: const Text('Guardar')),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar pieza'),
        content: Text('Eliminar "${song.title}" de manera permanente?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                prov.delete(song.id);
              },
              child: const Text('Eliminar')),
        ],
      ),
    );
  }
}