import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_tuner/features/pitch_detection/harmonic_spectrum_analyzer.dart';
import 'package:simple_tuner/features/tunings/tuning_catalog.dart';

void main() {
  const analyzer = HarmonicSpectrumAnalyzer();
  final standardFrequencies = [
    for (final note in TuningCatalog.standard.notes) note.frequency(),
  ];

  test('distinguishes low E2 harmonic pattern from high E4', () {
    final result = analyzer.analyze(
      pcm16Bytes: _harmonicWave(82.41),
      sampleRate: 44100,
      fundamentalFrequencies: standardFrequencies,
    );

    expect(result, isNotNull);
    expect(result!.bestIndex, 0);
    expect(result.confidence, greaterThan(0.52));
  });

  test('distinguishes high E4 from low E2 fourth harmonic', () {
    final result = analyzer.analyze(
      pcm16Bytes: _harmonicWave(329.63),
      sampleRate: 44100,
      fundamentalFrequencies: standardFrequencies,
    );

    expect(result, isNotNull);
    expect(result!.bestIndex, 5);
    expect(result.confidence, greaterThan(0.52));
  });

  test('identifies every standard string from its harmonic pattern', () {
    for (var index = 0; index < standardFrequencies.length; index++) {
      final result = analyzer.analyze(
        pcm16Bytes: _harmonicWave(standardFrequencies[index]),
        sampleRate: 44100,
        fundamentalFrequencies: standardFrequencies,
      );

      expect(
        result?.bestIndex,
        index,
        reason: 'Wrong spectral match for string index $index',
      );
    }
  });
}

Uint8List _harmonicWave(double fundamental) {
  const sampleRate = 44100;
  const sampleCount = 8192;
  const amplitudes = [0.32, 0.42, 0.20, 0.12];
  final bytes = Uint8List(sampleCount * 2);
  final data = ByteData.sublistView(bytes);

  for (var index = 0; index < sampleCount; index++) {
    var value = 0.0;
    for (var harmonic = 1; harmonic <= amplitudes.length; harmonic++) {
      value +=
          amplitudes[harmonic - 1] *
          math.sin(2 * math.pi * fundamental * harmonic * index / sampleRate);
    }
    data.setInt16(index * 2, (value * 22000).round(), Endian.little);
  }
  return bytes;
}
