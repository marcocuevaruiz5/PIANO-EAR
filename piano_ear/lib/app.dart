import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';

class PianoEarApp extends StatefulWidget {
  const PianoEarApp({super.key});

  @override
  State<PianoEarApp> createState() => _PianoEarAppState();
}

class _PianoEarAppState extends State<PianoEarApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Piano Ear',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: HomeScreen(),
    );
  }
}