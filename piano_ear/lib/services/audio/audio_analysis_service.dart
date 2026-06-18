import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/music_math.dart';
import '../../data/models/note_event.dart';
import 'fft.dart';
import 'polyphonic_analyzer.dart';
import 'tempo_estimator.dart';
import 'yin_pitch_detector.dart';

class LiveAnalysisState {
  final Set<int> activeMidiNotes;
  final List<NoteEvent> completedNotes;
  final double currentRms;

  const LiveAnalysisState({
    required this.activeMidiNotes,
    required this.completedNotes,
    required this.currentRms,
  });
}

class AnalysisResult {
  final List<NoteEvent> notes;
  final double tempoBpm;
  final String? audioFilePath;

  const AnalysisResult({
    required this.notes,
    required this.tempoBpm,
    this.audioFilePath,
  });
}

class AudioAnalysisService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final YinPitchDetector _yin;
  final PolyphonicAnalyzer _polyAnalyzer;

  StreamSubscription<dynamic>? _audioSub;
  StreamController<LiveAnalysisState>? _stateController;
  StreamController<dynamic>? _pcmController;

  final List<double> _sampleBuffer = [];
  final Map<int, _ActiveNote> _active = {};
  final List<NoteEvent> _completed = [];

  int _elapsedMs = 0;
  bool _isRecording = false;

  static const int _minNoteDurationMs = 80;
  static const int _silenceWindowMs = 120;

  AudioAnalysisService()
      : _yin = YinPitchDetector(sampleRate: AppConstants.sampleRate.toDouble()),
        _polyAnalyzer =
            PolyphonicAnalyzer(sampleRate: AppConstants.sampleRate.toDouble());

  Stream<LiveAnalysisState>? get liveState => _stateController?.stream;
  bool get isRecording => _isRecording;

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> startRecording() async {
    if (_isRecording) return;
    final granted = await requestPermission();
    if (!granted) throw Exception('Permiso de microfono denegado.');

    await _recorder.openRecorder();

    _stateController = StreamController<LiveAnalysisState>.broadcast();
    _pcmController = StreamController<dynamic>();
    _sampleBuffer.clear();
    _active.clear();
    _completed.clear();
    _elapsedMs = 0;
    _isRecording = true;

    await _recorder.startRecording(
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: AppConstants.sampleRate,
      toStream: _pcmController!.sink as StreamSink<dynamic>,
    );

    _audioSub = _pcmController!.stream.listen((dynamic data) {
      if (data is List<int>) _processAudioBytes(data);
    });
  }

  Future<AnalysisResult> stopRecording() async {
    if (!_isRecording) {
      return const AnalysisResult(notes: [], tempoBpm: 120);
    }
    _isRecording = false;

    await _audioSub?.cancel();
    _audioSub = null;
    await _recorder.stopRecorder();
    await _recorder.closeRecorder();
    await _pcmController?.close();
    _pcmController = null;

    for (final entry in _active.entries) {
      final a = entry.value;
      final dur = _elapsedMs - a.startMs;
      if (dur >= _minNoteDurationMs) {
        _completed.add(NoteEvent(
          midi: entry.key,
          frequencyHz: MusicMath.midiToFrequency(entry.key.toDouble()),
          startTimeMs: a.startMs,
          durationMs: dur,
          velocity: _rmsToVelocity(a.maxRms),
        ));
      }
    }
    _active.clear();
    _completed.sort((a, b) => a.startTimeMs.compareTo(b.startTimeMs));

    final onsets = _completed.map((n) => n.startTimeMs).toList();
    final bpm = TempoEstimator.estimate(onsets);

    _stateController?.close();
    _stateController = null;

    return AnalysisResult(notes: List.from(_completed), tempoBpm: bpm);
  }

  void _processAudioBytes(List<int> bytes) {
    for (int i = 0; i + 1 < bytes.length; i += 2) {
      final s16 = bytes[i] | (bytes[i + 1] << 8);
      final signed = s16 > 32767 ? s16 - 65536 : s16;
      _sampleBuffer.add(signed / 32768.0);
    }

    while (_sampleBuffer.length >= AppConstants.analysisFrameSize) {
      final frame = _sampleBuffer.sublist(0, AppConstants.analysisFrameSize);
      _analyzeFrame(frame);
      _sampleBuffer.removeRange(0, AppConstants.hopSize);
      _elapsedMs +=
          (AppConstants.hopSize / AppConstants.sampleRate * 1000).round();
    }
  }

  void _analyzeFrame(List<double> frame) {
    final energy = YinPitchDetector.rms(frame);
    final isSilent = energy < AppConstants.silenceRmsThreshold;
    final nowActive = <int>{};

    if (!isSilent) {
      final yinFreq = _yin.detectPitch(frame);
      if (yinFreq != null &&
          yinFreq >= AppConstants.minFrequencyHz &&
          yinFreq <= AppConstants.maxFrequencyHz) {
        nowActive.add(MusicMath.frequencyToNearestMidi(yinFreq));
      }
      final windowed = FFT.hannWindow(frame);
      nowActive.addAll(_polyAnalyzer.detectActivePitches(windowed));
    }

    final toClose = <int>[];
    for (final entry in _active.entries) {
      if (!nowActive.contains(entry.key)) {
        if (_elapsedMs - entry.value.lastSeenMs > _silenceWindowMs) {
          toClose.add(entry.key);
        }
      } else {
        entry.value
          ..lastSeenMs = _elapsedMs
          ..maxRms = math.max(entry.value.maxRms, energy);
      }
    }

    for (final midi in toClose) {
      final a = _active.remove(midi)!;
      final dur = a.lastSeenMs - a.startMs;
      if (dur >= _minNoteDurationMs) {
        _completed.add(NoteEvent(
          midi: midi,
          frequencyHz: MusicMath.midiToFrequency(midi.toDouble()),
          startTimeMs: a.startMs,
          durationMs: dur,
          velocity: _rmsToVelocity(a.maxRms),
        ));
      }
    }

    for (final midi in nowActive) {
      if (!_active.containsKey(midi)) {
        _active[midi] = _ActiveNote(
          startMs: _elapsedMs,
          lastSeenMs: _elapsedMs,
          maxRms: energy,
        );
      }
    }

    _stateController?.add(LiveAnalysisState(
      activeMidiNotes: Set.from(nowActive),
      completedNotes: List.unmodifiable(_completed),
      currentRms: energy,
    ));
  }

  int _rmsToVelocity(double rms) {
    final clamped = rms.clamp(0.01, 1.0);
    final logVal = (math.log(clamped) - math.log(0.01)) /
        (math.log(1.0) - math.log(0.01));
    return (20 + logVal * 107).round().clamp(20, 127);
  }

  void dispose() {
    _audioSub?.cancel();
    _recorder.closeRecorder();
    _stateController?.close();
    _pcmController?.close();
  }
}

class _ActiveNote {
  int startMs;
  int lastSeenMs;
  double maxRms;

  _ActiveNote({required this.startMs, required this.lastSeenMs, required this.maxRms});
}
