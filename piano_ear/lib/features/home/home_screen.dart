import 'package:flutter/material.dart';
import '../library/library_screen.dart';
import '../recording/recording_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Piano Ear',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text('Escucha. Transcribe. Aprende.',
                  style: TextStyle(
                      fontSize: 15,
                      color: scheme.onSurface.withOpacity(0.55))),
              const SizedBox(height: 48),
              _ActionCard(
                icon: Icons.mic_rounded,
                title: 'Grabar nueva pieza',
                subtitle: 'Toca el piano y transcribe en tiempo real.',
                color: scheme.primary,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RecordingScreen())),
              ),
              const SizedBox(height: 16),
              _ActionCard(
                icon: Icons.library_music_rounded,
                title: 'Mi biblioteca',
                subtitle: 'Revisa, practica y edita tus grabaciones.',
                color: scheme.secondary,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LibraryScreen())),
              ),
              const Spacer(),
              Center(
                child: Text('Mantén el celular cerca del piano\npara mejor detección.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withOpacity(0.38))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard(
      {required this.icon, required this.title, required this.subtitle,
       required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55))),
              ]),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          ]),
        ),
      ),
    );
  }
}