import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

/// Owns device microphone access and exposes raw mono PCM16 audio.
///
/// Pitch detection should consume this stream without depending on [record].
class AudioInputService {
  AudioInputService({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  final StreamController<int> _sampleRates = StreamController<int>.broadcast();

  Stream<int> get sampleRates => _sampleRates.stream;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<Stream<Uint8List>> start() async {
    await _recorder.setOnConfigChanged((config) {
      _sampleRates.add(config.sampleRate);
    });

    const requestedConfig = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 44100,
      numChannels: 1,
      autoGain: false,
      echoCancel: false,
      noiseSuppress: false,
    );
    final stream = await _recorder.startStream(requestedConfig);
    return stream;
  }

  Future<void> stop() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  Future<void> dispose() async {
    await _recorder.setOnConfigChanged(null);
    await _recorder.dispose();
    await _sampleRates.close();
  }
}
