import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/note_event.dart';
import '../../data/models/practice_result.dart';
import '../../data/models/song.dart';
import '../../data/repositories/song_repository.dart';
import '../../services/audio/audio_analysis_service.dart';

enum LearningStatus { idle, playing, paused, finished }

class LearningProvider extends ChangeNotifier {
  final Song song;
  final SongRepository _repo;
  final AudioAnalysisService _audio = AudioAnalysisService();

  LearningStatus _status = LearningStatus.idle;
  int _currentGroupIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;

  late final List<_NoteGroup> _groups;
  final List<FallingNote> fallingNotes = [];
  Set<int> _heard = {};
  Timer? _animTimer;
  StreamSubscription<dynamic>? _audioSub;

  static const double _visibleWindowSec = 3.0;
  double get _dropPerFrame => 1.0 / (_visibleWindowSec * 1000.0 / 16.0);

  LearningProvider({required this.song, SongRepository? repo})
      : _repo = repo ?? SongRepository() {
    _groups = _buildGroups(song.notes);
  }

  LearningStatus get status => _status;
  int get currentGroupIndex => _currentGroupIndex;
  int get totalGroups => _groups.length;
  int get correctCount => _correctCount;
  int get wrongCount => _wrongCount;
  Set<int> get expectedMidi => _currentGroupIndex < _groups.length
      ? _groups[_currentGroupIndex].midiSet
      : {};
  Set<int> get heardMidi => _heard;
  double get progressPercent =>
      _groups.isEmpty ? 0 : _currentGroupIndex / _groups.length;

  Future<void> start() async {
    if (_status != LearningStatus.idle) return;
    _currentGroupIndex = 0;
    _correctCount = 0;
    _wrongCount = 0;
    fallingNotes.clear();
    _status = LearningStatus.playing;
    notifyListeners();

    await _audio.requestPermission();
    try {
      await _audio.startRecording();
      _audioSub = _audio.liveState?.listen((state) {
        _heard = state.activeMidiNotes;
        _evaluateInput();
      });
    } catch (_) {}

    _spawnUpcomingNotes();
    _startAnimTimer();
  }

  void _startAnimTimer() {
    _animTimer?.cancel();
    _animTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_status == LearningStatus.paused ||
          _status == LearningStatus.finished) return;
      _tickFallingNotes();
      notifyListeners();
    });
  }

  void _spawnUpcomingNotes() {
    for (int i = _currentGroupIndex;
        i < _groups.length && i < _currentGroupIndex + 20;
        i++) {
      for (final midi in _groups[i].midiSet) {
        if (!fallingNotes.any((fn) => fn.groupIndex == i && fn.midi == midi)) {
          final delay = (i - _currentGroupIndex) / 8.0;
          // Cast explicito a double para evitar error de tipo num
          final yStart = -(delay.clamp(0.0, 1.0));
          fallingNotes.add(FallingNote(
              midi: midi, groupIndex: i, y: yStart.toDouble()));
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

    final currentNotes = fallingNotes
        .where((fn) => fn.groupIndex == _currentGroupIndex && !fn.hit);
    if (currentNotes.isNotEmpty &&
        currentNotes.every((fn) => fn.y >= 1.0) &&
        _status == LearningStatus.playing) {
      _status = LearningStatus.paused;
    }
  }

  void _evaluateInput() {
    if (_status != LearningStatus.paused) return;
    if (_currentGroupIndex >= _groups.length) return;
    final expected = _groups[_currentGroupIndex].midiSet;

    if (expected.every((m) => _heard.contains(m))) {
      _markCurrentGroupCorrect();
    } else if (_heard.isNotEmpty &&
        !_heard.any((m) => expected.contains(m))) {
      _wrongCount++;
      notifyListeners();
    }
  }

  void _markCurrentGroupCorrect() {
    for (final fn in fallingNotes) {
      if (fn.groupIndex == _currentGroupIndex) fn.hit = true;
    }
    _correctCount += _groups[_currentGroupIndex].midiSet.length;
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
      totalExpectedNotes:
          _groups.fold(0, (s, g) => s + g.midiSet.length),
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
    final sorted = [...notes]
      ..sort((a, b) => a.startTimeMs.compareTo(b.startTimeMs));
    final groups = <_NoteGroup>[];
    for (final note in sorted) {
      if (groups.isNotEmpty &&
          (note.startTimeMs - groups.last.startTimeMs).abs() <= windowMs) {
        groups.last.midiSet.add(note.midi);
      } else {
        groups.add(
            _NoteGroup(startTimeMs: note.startTimeMs, midiSet: {note.midi}));
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

class FallingNote {
  final int midi;
  final int groupIndex;
  double y;
  bool hit;
  FallingNote(
      {required this.midi,
      required this.groupIndex,
      required this.y,
      this.hit = false});
}