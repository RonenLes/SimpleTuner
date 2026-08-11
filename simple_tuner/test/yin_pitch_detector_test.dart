import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_tuner/features/pitch_detection/yin_pitch_detector.dart';

void main() {
  test('detects an A2 sine wave near 110 Hz', () {
    const detector = YinPitchDetector();
    final pcm = _sineWave(frequency: 110, sampleCount: 4096);

    final result = detector.detect(pcm);

    expect(result, isNotNull);
    expect(result!.frequencyHz, closeTo(110, 0.5));
    expect(result.confidence, greaterThan(0.8));
  });

  test('uses the effective 48 kHz device sample rate', () {
    const detector = YinPitchDetector(sampleRate: 48000);
    final pcm = _sineWave(
      frequency: 82.41,
      sampleCount: 4096,
      sampleRate: 48000,
    );

    final result = detector.detect(pcm);

    expect(result, isNotNull);
    expect(result!.frequencyHz, closeTo(82.41, 0.5));
  });

  test('separates all standard strings with strong guitar harmonics', () {
    const expectedFrequencies = [82.41, 110.0, 146.83, 196.0, 246.94, 329.63];

    for (final expectedFrequency in expectedFrequencies) {
      final result = const YinPitchDetector().detect(
        _guitarLikeWave(frequency: expectedFrequency, sampleCount: 4096),
      );

      expect(result, isNotNull, reason: 'No result for $expectedFrequency Hz');
      expect(
        result!.frequencyHz,
        closeTo(expectedFrequency, 1),
        reason: 'Wrong result for $expectedFrequency Hz',
      );
    }
  });

  test('detects a quiet low E2 using a long tuner window', () {
    final result = const YinPitchDetector().detect(
      _sineWave(frequency: 82.41, sampleCount: 8192, amplitude: 150),
    );

    expect(result, isNotNull);
    expect(result!.frequencyHz, closeTo(82.41, 0.5));
  });
}

Uint8List _sineWave({
  required double frequency,
  required int sampleCount,
  int sampleRate = 44100,
  int amplitude = 20000,
}) {
  final bytes = Uint8List(sampleCount * 2);
  final data = ByteData.sublistView(bytes);

  for (var index = 0; index < sampleCount; index++) {
    final value = math.sin(2 * math.pi * frequency * index / sampleRate);
    data.setInt16(index * 2, (value * amplitude).round(), Endian.little);
  }
  return bytes;
}

Uint8List _guitarLikeWave({
  required double frequency,
  required int sampleCount,
  int sampleRate = 44100,
}) {
  final bytes = Uint8List(sampleCount * 2);
  final data = ByteData.sublistView(bytes);

  for (var index = 0; index < sampleCount; index++) {
    final phase = 2 * math.pi * frequency * index / sampleRate;
    final value =
        0.35 * math.sin(phase) +
        0.45 * math.sin(phase * 2) +
        0.20 * math.sin(phase * 3);
    data.setInt16(index * 2, (value * 20000).round(), Endian.little);
  }
  return bytes;
}
