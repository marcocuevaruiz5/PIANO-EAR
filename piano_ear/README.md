# Piano Ear 🎹

Aplicacion Flutter multiplataforma (Android / iOS) que escucha un piano real
o digital a traves del microfono, transcribe las notas en tiempo real y
permite aprender la pieza grabada con un modo tipo "Synthesia".

## Estructura de carpetas

```
lib/
  core/
    constants/   piano_constants.dart, app_constants.dart
    theme/       app_theme.dart
    utils/       music_math.dart
  data/
    models/      note_event.dart, song.dart, practice_result.dart
    db/          database_helper.dart
    repositories/ song_repository.dart
  services/
    audio/       fft.dart, yin_pitch_detector.dart,
                 polyphonic_analyzer.dart, tempo_estimator.dart,
                 audio_analysis_service.dart
    playback/    playback_service.dart
  features/
    home/        home_screen.dart
    recording/   recording_provider.dart, recording_screen.dart
    library/     library_provider.dart, library_screen.dart
    sheet_music/ sheet_music_painter.dart, sheet_music_screen.dart
    learning/    learning_provider.dart, learning_screen.dart,
                 falling_notes_painter.dart, keyboard_88_painter.dart
  app.dart
  main.dart
```

## Algoritmo de deteccion de tono

- **YIN** (Cheveigné & Kawahara, 2002): algoritmo clasico de tiempo de
  dominio; muy preciso para notas monofónicas, ligero en CPU.
- **FFT + supresion de armonicos**: para acordes de hasta 6 notas
  simultaneas.
- **TempoEstimator**: autocorrelacion de inter-onset intervals para
  estimar BPM a partir de los instantes de inicio de cada nota.

## Pasos para compilar

```bash
flutter pub get
flutter run           # en dispositivo o emulador conectado
flutter build apk     # para Android
flutter build ios     # para iOS (requiere Mac + Xcode)
```

## Permisos requeridos

- **Android**: `RECORD_AUDIO`, `WRITE_EXTERNAL_STORAGE` (ver `android/app/src/main/AndroidManifest.xml`)
- **iOS**: `NSMicrophoneUsageDescription` (ver `ios/Runner/Info.plist`)

## Notas tecnicas

- El pipeline de audio corre en el isolate principal de Flutter; para
  producccion se recomienda mover el analisis FFT/YIN a un `Isolate`
  separado usando `compute()` o `flutter_isolate`.
- La deteccion polifonica tiene precision limitada frente a acordes de
  mas de 4 notas muy cercanas en frecuencia (intervalos de semitono).
  El roadmap incluye sustituir el modulo por un modelo TFLite on-device
  ("Onsets and Frames" de Google Magenta).
- La partitura generada es una aproximacion cualitativa; no reemplaza
  a un editor de partituras profesional como MuseScore o Sibelius.