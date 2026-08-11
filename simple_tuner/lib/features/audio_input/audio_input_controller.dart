import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:simple_tuner/features/audio_input/audio_input_service.dart';
import 'package:simple_tuner/features/audio_input/audio_input_state.dart';

class AudioInputController extends ChangeNotifier {
  AudioInputController({AudioInputService? service})
    : _service = service ?? AudioInputService();

  final AudioInputService _service;
  final StreamController<Uint8List> _audioChunks =
      StreamController<Uint8List>.broadcast();
  StreamSubscription<Uint8List>? _subscription;
  StreamSubscription<int>? _sampleRateSubscription;
  AudioInputState _state = const AudioInputState();

  AudioInputState get state => _state;
  Stream<Uint8List> get audioChunks => _audioChunks.stream;
  Stream<int> get sampleRates => _service.sampleRates;

  Future<void> start() async {
    if (_state.isListening) return;

    _setState(
      const AudioInputState(status: AudioInputStatus.requestingPermission),
    );

    try {
      if (!await _service.hasPermission()) {
        _setState(const AudioInputState(status: AudioInputStatus.denied));
        return;
      }

      _sampleRateSubscription ??= _service.sampleRates.listen((sampleRate) {
        _setState(_state.copyWith(sampleRate: sampleRate));
      });
      final stream = await _service.start();
      _setState(
        AudioInputState(
          status: AudioInputStatus.listening,
          sampleRate: _state.sampleRate,
        ),
      );
      _subscription = stream.listen(
        _onAudioChunk,
        onError: (Object error) => _setError(error),
        onDone: _onStreamDone,
        cancelOnError: true,
      );
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    await _sampleRateSubscription?.cancel();
    _subscription = null;
    _sampleRateSubscription = null;
    await _service.stop();
    _setState(const AudioInputState());
  }

  void _onAudioChunk(Uint8List bytes) {
    _audioChunks.add(bytes);
    final measuredLevel = _measureAudioLevel(bytes);
    final currentLevel = _state.audioLevel;
    final smoothing = measuredLevel > currentLevel ? 0.65 : 0.18;
    final smoothedLevel =
        currentLevel + (measuredLevel - currentLevel) * smoothing;

    _setState(
      _state.copyWith(
        bytesReceived: _state.bytesReceived + bytes.length,
        audioLevel: smoothedLevel.clamp(0.0, 1.0),
      ),
    );
  }

  double _measureAudioLevel(Uint8List bytes) {
    final sampleCount = bytes.length ~/ 2;
    if (sampleCount == 0) return 0;

    final data = ByteData.sublistView(bytes);
    var sumOfSquares = 0.0;

    for (var sampleIndex = 0; sampleIndex < sampleCount; sampleIndex++) {
      final sample = data.getInt16(sampleIndex * 2, Endian.little);
      final normalizedSample = sample / 32768.0;
      sumOfSquares += normalizedSample * normalizedSample;
    }

    final rms = math.sqrt(sumOfSquares / sampleCount);
    if (rms <= 0.000001) return 0;

    // Convert RMS to decibels and map -60 dB..0 dB onto the visible bar.
    final decibels = 20 * (math.log(rms) / math.ln10);
    return ((decibels + 60) / 60).clamp(0.0, 1.0);
  }

  void _onStreamDone() {
    _subscription = null;
    _setState(const AudioInputState());
  }

  void _setError(Object error) {
    _subscription = null;
    _setState(
      AudioInputState(
        status: AudioInputStatus.error,
        errorMessage: error.toString(),
      ),
    );
  }

  void _setState(AudioInputState value) {
    _state = value;
    notifyListeners();
  }

  Future<void> disposeAsync() async {
    await _subscription?.cancel();
    await _sampleRateSubscription?.cancel();
    await _service.stop();
    await _service.dispose();
    await _audioChunks.close();
  }

  @override
  void dispose() {
    unawaited(disposeAsync());
    super.dispose();
  }
}
