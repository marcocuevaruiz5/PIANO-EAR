import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../../data/models/note_event.dart';

/// Servicio de reproduccion de canciones grabadas. Sincroniza el audio
/// con eventos de nota para que la partitura y el teclado se animen.
class PlaybackService {
  final AudioPlayer _player = AudioPlayer();
  Timer? _ticker;
  List<NoteEvent> _notes = [];

  final StreamController<Set<int>> _activeCtrl =
      StreamController<Set<int>>.broadcast();

  Stream<Set<int>> get activeNotes => _activeCtrl.stream;
  Stream<Duration> get position => _player.positionStream;
  Stream<PlayerState> get playerState => _player.playerStateStream;
  bool get isPlaying => _player.playing;
  Duration get currentPosition => _player.position;

  Future<void> loadSong({required List<NoteEvent> notes, String? audioFilePath}) async {
    _notes = notes;
    if (audioFilePath != null) {
      await _player.setFilePath(audioFilePath);
    }
  }

  Future<void> play() async {
    await _player.play();
    _startTicker();
  }

  Future<void> pause() async {
    await _player.pause();
    _ticker?.cancel();
  }

  Future<void> stop() async {
    _ticker?.cancel();
    await _player.stop();
    _activeCtrl.add({});
  }

  Future<void> seek(Duration pos) async {
    await _player.seek(pos);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final posMs = _player.position.inMilliseconds;
      final active = <int>{};
      for (final note in _notes) {
        if (posMs >= note.startTimeMs && posMs <= note.endTimeMs) {
          active.add(note.midi);
        }
      }
      _activeCtrl.add(active);
    });
  }

  void dispose() {
    _ticker?.cancel();
    _player.dispose();
    _activeCtrl.close();
  }
}