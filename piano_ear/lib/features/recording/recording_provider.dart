import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/note_event.dart';
import '../../data/models/song.dart';
import '../../data/repositories/song_repository.dart';
import '../../services/audio/audio_analysis_service.dart';

enum RecordingStatus { idle, recording, processing, done }

class RecordingProvider extends ChangeNotifier {
  final AudioAnalysisService _audioService = AudioAnalysisService();
  final SongRepository _repo;

  RecordingStatus _status = RecordingStatus.idle;
  Set<int> _activeMidi = {};
  List<NoteEvent> _liveNotes = [];
  double _rms = 0;
  String? _errorMessage;
  Song? _lastSavedSong;

  RecordingProvider({SongRepository? repo})
      : _repo = repo ?? SongRepository();

  RecordingStatus get status => _status;
  Set<int> get activeMidi => _activeMidi;
  List<NoteEvent> get liveNotes => _liveNotes;
  double get rms => _rms;
  String? get errorMessage => _errorMessage;
  Song? get lastSavedSong => _lastSavedSong;
  bool get isRecording => _status == RecordingStatus.recording;

  Stream<LiveAnalysisState>? get liveStream => _audioService.liveState;

  Future<void> startRecording() async {
    _errorMessage = null;
    try {
      await _audioService.startRecording();
      _status = RecordingStatus.recording;
      notifyListeners();

      _audioService.liveState?.listen((state) {
        _activeMidi = state.activeMidiNotes;
        _liveNotes = List.from(state.completedNotes);
        _rms = state.currentRms;
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = e.toString();
      _status = RecordingStatus.idle;
      notifyListeners();
    }
  }

  Future<void> stopAndSave(String title) async {
    if (_status != RecordingStatus.recording) return;
    _status = RecordingStatus.processing;
    notifyListeners();

    final result = await _audioService.stopRecording();
    final song = Song(
      id: const Uuid().v4(),
      title: title,
      createdAt: DateTime.now(),
      durationMs: result.notes.isEmpty
          ? 0
          : (result.notes.last.endTimeMs),
      tempoBpm: result.tempoBpm,
      notes: result.notes,
      audioFilePath: result.audioFilePath,
    );

    await _repo.saveSong(song);
    _lastSavedSong = song;
    _status = RecordingStatus.done;
    notifyListeners();
  }

  void reset() {
    _status = RecordingStatus.idle;
    _activeMidi = {};
    _liveNotes = [];
    _rms = 0;
    _errorMessage = null;
    _lastSavedSong = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}