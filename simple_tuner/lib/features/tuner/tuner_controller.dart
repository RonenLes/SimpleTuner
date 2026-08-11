import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:simple_tuner/features/audio_input/audio_input_controller.dart';
import 'package:simple_tuner/features/pitch_detection/detected_note.dart';
import 'package:simple_tuner/features/pitch_detection/domain/pitch_detector.dart';
import 'package:simple_tuner/features/pitch_detection/domain/pitch_result.dart';
import 'package:simple_tuner/features/pitch_detection/harmonic_spectrum_analyzer.dart';
import 'package:simple_tuner/features/pitch_detection/yin_pitch_detector.dart';
import 'package:simple_tuner/features/tuner/tuner_state.dart';
import 'package:simple_tuner/features/tunings/tuning_match.dart';
import 'package:simple_tuner/features/tunings/tuning_matcher.dart';
import 'package:simple_tuner/features/tunings/tuning_preset.dart';

class TunerController extends ChangeNotifier {
  TunerController({
    AudioInputController? audioInputController,
    PitchDetector? pitchDetector,
    HarmonicSpectrumAnalyzer? spectrumAnalyzer,
    TuningMatcher? tuningMatcher,
  }) : audioInput = audioInputController ?? AudioInputController(),
       _pitchDetector = pitchDetector ?? const YinPitchDetector(),
       _usesDefaultPitchDetector = pitchDetector == null,
       _spectrumAnalyzer = spectrumAnalyzer ?? const HarmonicSpectrumAnalyzer(),
       _tuningMatcher = tuningMatcher ?? const TuningMatcher() {
    _audioSubscription = audioInput.audioChunks.listen(_onAudioChunk);
    _sampleRateSubscription = audioInput.sampleRates.listen(
      _onSampleRateChanged,
    );
  }

  static const int _windowByteCount = 16384;
  static const int _hopByteCount = 4096;
  static const int _smoothingWindowSize = 5;
  static const int _missesBeforeClearing = 12;
  static const int _consistentReadingsToLock = 3;
  static const int _spectralReadingsBeforeSwitch = 2;
  static const double _minimumConfidence = 0.85;
  static const double _minimumSpectralConfidence = 0.52;
  static const double _centsSmoothing = 0.28;
  static const double _inTuneToleranceCents = 5;

  final AudioInputController audioInput;
  PitchDetector _pitchDetector;
  final bool _usesDefaultPitchDetector;
  final HarmonicSpectrumAnalyzer _spectrumAnalyzer;
  final TuningMatcher _tuningMatcher;
  final List<int> _audioBuffer = [];
  final List<double> _recentFrequencies = [];
  late final StreamSubscription<Uint8List> _audioSubscription;
  late final StreamSubscription<int> _sampleRateSubscription;

  TunerState _state = const TunerState();
  int _sampleRate = 44100;
  int _consecutiveMisses = 0;
  int? _stableSpectralStringIndex;
  int? _pendingSpectralStringIndex;
  int _pendingSpectralCount = 0;
  double _spectralConfidence = 0;
  int? _lockedStringIndex;
  int? _candidateStringIndex;
  int _candidateCount = 0;
  TunerLockStatus _lockStatus = TunerLockStatus.waiting;
  double? _smoothedCents;
  int? _smoothedCentsStringIndex;

  TunerState get state => _state;

  void selectTuning(TuningPreset tuning) {
    _resetDetection();
    _state = TunerState(
      selectedTuning: tuning,
      selectionMode: _state.selectionMode,
      selectedStringIndex: _state.selectedStringIndex.clamp(
        0,
        tuning.notes.length - 1,
      ),
    );
    notifyListeners();
  }

  void selectMode(StringSelectionMode mode) {
    _resetLock();
    if (mode == StringSelectionMode.manual) {
      _lockedStringIndex = _state.selectedStringIndex;
      _lockStatus = TunerLockStatus.locked;
    }
    _state = TunerState(
      selectedTuning: _state.selectedTuning,
      selectionMode: mode,
      selectedStringIndex: _state.selectedStringIndex,
      lockStatus: _lockStatus,
    );
    notifyListeners();
  }

  void selectString(int index) {
    _resetLock();
    _lockedStringIndex = index;
    _lockStatus = TunerLockStatus.locked;
    _state = TunerState(
      selectedTuning: _state.selectedTuning,
      selectionMode: StringSelectionMode.manual,
      selectedStringIndex: index,
      lockStatus: _lockStatus,
    );
    notifyListeners();
  }

  void _onAudioChunk(Uint8List bytes) {
    _audioBuffer.addAll(bytes);

    while (_audioBuffer.length >= _windowByteCount) {
      final window = Uint8List.fromList(
        _audioBuffer.sublist(0, _windowByteCount),
      );
      _analyzeSpectrum(window);
      _handlePitchResult(_pitchDetector.detect(window));
      _audioBuffer.removeRange(0, _hopByteCount);
    }
  }

  void _onSampleRateChanged(int sampleRate) {
    _sampleRate = sampleRate;
    if (_usesDefaultPitchDetector) {
      _pitchDetector = YinPitchDetector(sampleRate: sampleRate);
    }
    _resetDetection();
  }

  void _analyzeSpectrum(Uint8List window) {
    final result = _spectrumAnalyzer.analyze(
      pcm16Bytes: window,
      sampleRate: _sampleRate,
      fundamentalFrequencies: [
        for (final note in _state.selectedTuning.notes) note.frequency(),
      ],
    );

    if (result == null || result.confidence < _minimumSpectralConfidence) {
      _spectralConfidence = 0;
      return;
    }

    _spectralConfidence = result.confidence;
    final candidate = result.bestIndex;
    if (_stableSpectralStringIndex == null) {
      _stableSpectralStringIndex = candidate;
      return;
    }
    if (candidate == _stableSpectralStringIndex) {
      _pendingSpectralStringIndex = null;
      _pendingSpectralCount = 0;
      return;
    }

    if (candidate == _pendingSpectralStringIndex) {
      _pendingSpectralCount++;
    } else {
      _pendingSpectralStringIndex = candidate;
      _pendingSpectralCount = 1;
    }
    if (_pendingSpectralCount >= _spectralReadingsBeforeSwitch) {
      _stableSpectralStringIndex = candidate;
      _pendingSpectralStringIndex = null;
      _pendingSpectralCount = 0;
    }
  }

  void _handlePitchResult(PitchResult? result) {
    if (result == null || result.confidence < _minimumConfidence) {
      _handleMissedReading();
      return;
    }

    _consecutiveMisses = 0;
    _recentFrequencies.add(result.frequencyHz);
    if (_recentFrequencies.length > _smoothingWindowSize) {
      _recentFrequencies.removeAt(0);
    }

    final smoothedFrequency = _median(_recentFrequencies);
    final suggestedString = _suggestedStringIndex(smoothedFrequency);
    final effectiveString = _updateStringLock(suggestedString);
    final rawMatch = _tuningMatcher.match(
      frequencyHz: smoothedFrequency,
      tuning: _state.selectedTuning,
      stringIndex: effectiveString,
    );
    final match = _smoothCents(rawMatch);

    _state = TunerState(
      frequencyHz: smoothedFrequency,
      confidence: result.confidence,
      selectedTuning: _state.selectedTuning,
      selectionMode: _state.selectionMode,
      selectedStringIndex: effectiveString,
      match: match,
      detectedNote: DetectedNote.fromFrequency(smoothedFrequency),
      spectralConfidence: _spectralConfidence,
      lockStatus: _lockStatus,
    );
    notifyListeners();
  }

  int _suggestedStringIndex(double frequencyHz) {
    if (_state.selectionMode == StringSelectionMode.manual) {
      return _state.selectedStringIndex;
    }
    return _stableSpectralStringIndex ??
        _tuningMatcher
            .match(frequencyHz: frequencyHz, tuning: _state.selectedTuning)
            .stringIndex;
  }

  int _updateStringLock(int suggestedString) {
    if (_state.selectionMode == StringSelectionMode.manual) {
      _lockedStringIndex = _state.selectedStringIndex;
      _lockStatus = TunerLockStatus.locked;
      return _lockedStringIndex!;
    }

    if (_lockedStringIndex == suggestedString) {
      _candidateStringIndex = null;
      _candidateCount = 0;
      _lockStatus = TunerLockStatus.locked;
      return suggestedString;
    }

    if (_candidateStringIndex == suggestedString) {
      _candidateCount++;
    } else {
      _candidateStringIndex = suggestedString;
      _candidateCount = 1;
    }

    if (_candidateCount >= _consistentReadingsToLock) {
      final previousLock = _lockedStringIndex;
      _lockedStringIndex = suggestedString;
      _candidateStringIndex = null;
      _candidateCount = 0;
      _lockStatus = TunerLockStatus.locked;
      if (previousLock != suggestedString) {
        _resetCentsSmoothing();
        _recentFrequencies.clear();
      }
    } else {
      _lockStatus = TunerLockStatus.analyzing;
    }

    return _lockedStringIndex ?? suggestedString;
  }

  TuningMatch _smoothCents(TuningMatch match) {
    if (_smoothedCentsStringIndex != match.stringIndex ||
        _smoothedCents == null) {
      _smoothedCentsStringIndex = match.stringIndex;
      _smoothedCents = match.cents;
    } else {
      _smoothedCents =
          _smoothedCents! + (match.cents - _smoothedCents!) * _centsSmoothing;
    }

    final cents = _smoothedCents!;
    final direction = cents.abs() <= _inTuneToleranceCents
        ? TuningDirection.inTune
        : cents < 0
        ? TuningDirection.flat
        : TuningDirection.sharp;
    return TuningMatch(
      stringIndex: match.stringIndex,
      note: match.note,
      targetFrequencyHz: match.targetFrequencyHz,
      measuredFrequencyHz: match.measuredFrequencyHz,
      estimatedFundamentalHz: match.estimatedFundamentalHz,
      harmonicNumber: match.harmonicNumber,
      subharmonicDivisor: match.subharmonicDivisor,
      cents: cents,
      direction: direction,
    );
  }

  void _handleMissedReading() {
    _consecutiveMisses++;
    if (_consecutiveMisses < _missesBeforeClearing) return;

    _resetDetection();
    _state = TunerState(
      selectedTuning: _state.selectedTuning,
      selectionMode: _state.selectionMode,
      selectedStringIndex: _state.selectedStringIndex,
    );
    notifyListeners();
  }

  double _median(List<double> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle];
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  void _resetDetection() {
    _audioBuffer.clear();
    _recentFrequencies.clear();
    _consecutiveMisses = 0;
    _stableSpectralStringIndex = null;
    _pendingSpectralStringIndex = null;
    _pendingSpectralCount = 0;
    _spectralConfidence = 0;
    _resetLock();
  }

  void _resetLock() {
    _lockedStringIndex = null;
    _candidateStringIndex = null;
    _candidateCount = 0;
    _lockStatus = TunerLockStatus.waiting;
    _resetCentsSmoothing();
  }

  void _resetCentsSmoothing() {
    _smoothedCents = null;
    _smoothedCentsStringIndex = null;
  }

  @override
  void dispose() {
    unawaited(_audioSubscription.cancel());
    unawaited(_sampleRateSubscription.cancel());
    audioInput.dispose();
    super.dispose();
  }
}
