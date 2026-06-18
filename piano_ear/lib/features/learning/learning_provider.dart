import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/note_event.dart';
import '../../data/models/practice_result.dart';
import '../../data/models/song.dart';
import '../../data/repositories/song_repository.dart';
import '../../services/audio/audio_analysis_service.dart';

enum LearningStatus { idle, playing, paused, finished }

/// Estado de una nota durante la reproduccion guiada:
/// waiting -> el usuario aun no la ha tocado.
/// correct  -> tocada correctamente.
/// wrong    -> tecla incorrecta.
enum NoteStatus { waiting, correct, wrong }

class LearningProvider extends ChangeNotifier {
  final Song song;
  final SongRepository _repo;
  final AudioAnalysisService _audio = AudioAnalysisService();

  LearningStatus _status = LearningStatus.idle;
  int _currentGroupIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;

  // Grupos de notas (acordes/notas individuales) ordenados por tiempo.
  late final List<_NoteGroup> _groups;

  // Notas que caen en la animacion (lluvia). Cada entrada lleva su
  // posicion Y normalizada [0,1] y si ya fue "golpeada".
  final List<FallingNote> fallingNotes = [];

  // Set de MIDI actualmente escuchados por el microfono.
  Set<int> _heard = {};

  // Temporizador que avanza la animacion cada 16 ms.
  Timer? _animTimer;
  StreamSubscription? _audioSub;

  // Cuanta ventana de tiempo (en segundos) se muestra en la pantalla.
  static const double _visibleWindowSec = 3.0;

  // Velocidad de caida normalizada por frame (16 ms).
  double get _dropPerFrame => 1 / (_visibleWindowSec * 1000 / 16);

  LearningProvider({required this.song, SongRepository? repo})
      : _repo = repo ?? SongRepository() {
    _groups = _buildGroups(song.notes);
  }

  LearningStatus get status => _status;
  int get currentGroupIndex => _currentGroupIndex;
  int get totalGroups => _groups.length;
  int get correctCount => _correctCount;
  int get wrongCount => _wrongCount;
  Set<int> get expectedMidi =>
      _currentGroupIndex < _groups.length
          ? _groups[_currentGroupIndex].midiSet
          : {};
  Set<int> get heardMidi => _heard;

  double get progressPercent =>
      _groups.isEmpty ? 0 : _currentGroupIndex / _groups.length;

  bool get _isPaused => _status == LearningStatus.paused;

  Future<void> start() async {
    if (_status != LearningStatus.idle) return;
    _currentGroupIndex = 0;
    _correctCount = 0;
    _wrongCount = 0;
    fallingNotes.clear();
    _status = LearningStatus.playing;
    notifyListeners();

    // Iniciar escucha del microfono.
    await _audio.requestPermission();
    try {
      await _audio.startRecording();
      _audioSub = _audio.liveState?.listen((state) {
        _heard = state.activeMidiNotes;
        _evaluateInput();
      });
    } catch (_) {
      // Si no hay microfono (simulador), continuar sin el.
    }

    _spawnUpcomingNotes();
    _startAnimTimer();
  }

  void _startAnimTimer() {
    _animTimer?.cancel();
    _animTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_isPaused) return;
      _tickFallingNotes();
      notifyListeners();
    });
  }

  // Pre-lanza notas que van a caer en los proximos [_visibleWindowSec].
  void _spawnUpcomingNotes() {
    for (int i = _currentGroupIndex;
        i < _groups.length && i < _currentGroupIndex + 20;
        i++) {
      final group = _groups[i];
      for (final midi in group.midiSet) {
        if (!fallingNotes.any((fn) => fn.groupIndex == i && fn.midi == midi)) {
          // Posicion Y inicial: 0 = tope, 1 = tecla.
          final delay = (i - _currentGroupIndex) / 8.0;
          fallingNotes.add(FallingNote(
            midi: midi,
            groupIndex: i,
            y: -delay.clamp(0, 1),
          ));
        }
      }
    }
  }

  void _tickFallingNotes() {
    for (final fn in fallingNotes) {
      if (!fn.hit) fn.y += _dropPerFrame;
    }
    fallingNotes.removeWhere((fn) => fn.y > 1.15 && fn.hit);

    _spawnUpcomingNotes();

    // Si la nota del grupo actual ha llegado a la tecla (y >= 1) y
    // no se ha evaluado aun, pausar.
    final currentGroupNotes =
        fallingNotes.where((fn) => fn.groupIndex == _currentGroupIndex && !fn.hit);
    if (currentGroupNotes.isNotEmpty &&
        currentGroupNotes.every((fn) => fn.y >= 1.0) &&
        _status == LearningStatus.playing) {
      _status = LearningStatus.paused;
    }
  }

  void _evaluateInput() {
    if (_status != LearningStatus.paused) return;
    if (_currentGroupIndex >= _groups.length) return;
    final expected = _groups[_currentGroupIndex].midiSet;

    // Verificar si el usuario toco todas las notas del grupo.
    if (expected.every((m) => _heard.contains(m))) {
      _markCurrentGroupCorrect();
    } else if (_heard.isNotEmpty &&
        !_heard.any((m) => expected.contains(m))) {
      // Toco algo completamente distinto -> incrementar error pero no avanzar.
      _wrongCount++;
      notifyListeners();
    }
  }

  void _markCurrentGroupCorrect() {
    final group = _groups[_currentGroupIndex];
    for (final fn in fallingNotes) {
      if (fn.groupIndex == _currentGroupIndex) fn.hit = true;
    }
    _correctCount += group.midiSet.length;
    _currentGroupIndex++;

    if (_currentGroupIndex >= _groups.length) {
      _finish();
      return;
    }

    _status = LearningStatus.playing;
    notifyListeners();
  }

  Future<void> _finish() async {
    _animTimer?.cancel();
    await _audio.stopRecording();
    _audioSub?.cancel();

    _status = LearningStatus.finished;
    notifyListeners();

    final result = PracticeResult(
      songId: song.id,
      date: DateTime.now(),
      correctNotes: _correctCount,
      wrongNotes: _wrongCount,
      missedNotes: 0,
      totalExpectedNotes: _groups.fold(0, (s, g) => s + g.midiSet.length),
    );
    await _repo.savePracticeResult(result);
  }

  void reset() {
    _animTimer?.cancel();
    _audio.stopRecording();
    _audioSub?.cancel();
    _status = LearningStatus.idle;
    _currentGroupIndex = 0;
    _correctCount = 0;
    _wrongCount = 0;
    fallingNotes.clear();
    _heard = {};
    notifyListeners();
  }

  static List<_NoteGroup> _buildGroups(List<NoteEvent> notes) {
    const windowMs = 60;
    final sorted = [...notes]..sort((a, b) => a.startTimeMs.compareTo(b.startTimeMs));
    final groups = <_NoteGroup>[];
    for (final note in sorted) {
      if (groups.isNotEmpty &&
          (note.startTimeMs - groups.last.startTimeMs).abs() <= windowMs) {
        groups.last.midiSet.add(note.midi);
      } else {
        groups.add(_NoteGroup(startTimeMs: note.startTimeMs, midiSet: {note.midi}));
      }
    }
    return groups;
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _audio.dispose();
    _audioSub?.cancel();
    super.dispose();
  }
}

class _NoteGroup {
  final int startTimeMs;
  final Set<int> midiSet;
  _NoteGroup({required this.startTimeMs, required this.midiSet});
}

/// Una nota cayendo en la animacion Synthesia.
class FallingNote {
  final int midi;
  final int groupIndex;
  double y; // 0 = tope, 1 = tecla del piano
  bool hit; // true cuando el usuario la toco correctamente

  FallingNote({
    required this.midi,
    required this.groupIndex,
    required this.y,
    this.hit = false,
  });
}