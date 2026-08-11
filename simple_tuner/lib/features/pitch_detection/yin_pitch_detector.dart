import 'dart:math' as math;
import 'dart:typed_data';

import 'package:simple_tuner/features/pitch_detection/domain/pitch_detector.dart';
import 'package:simple_tuner/features/pitch_detection/domain/pitch_result.dart';

/// Detects the fundamental frequency of one sustained note using YIN.
class YinPitchDetector implements PitchDetector {
  const YinPitchDetector({
    this.sampleRate = 44100,
    this.minimumFrequency = 50,
    this.maximumFrequency = 450,
    this.threshold = 0.15,
  });

  final int sampleRate;
  final double minimumFrequency;
  final double maximumFrequency;
  final double threshold;

  @override
  PitchResult? detect(Uint8List pcm16Bytes) {
    final sampleCount = pcm16Bytes.length ~/ 2;
    if (sampleCount < 2048) return null;

    final samples = _decodePcm16(pcm16Bytes, sampleCount);
    // Low guitar strings can reach the microphone at a much lower level than
    // speech or treble strings, especially on nylon-string instruments.
    if (_rms(samples) < 0.003) return null;

    final minimumLag = (sampleRate / maximumFrequency).floor();
    final maximumLag = math.min(
      (sampleRate / minimumFrequency).ceil(),
      sampleCount ~/ 2,
    );
    final difference = List<double>.filled(maximumLag + 1, 0);
    final comparisonLength = sampleCount - maximumLag;

    for (var lag = 1; lag <= maximumLag; lag++) {
      var sum = 0.0;
      // Every lag must compare the same number of samples. A varying length
      // unfairly lowers the difference at long lags and creates false notes.
      for (var index = 0; index < comparisonLength; index++) {
        final delta = samples[index] - samples[index + lag];
        sum += delta * delta;
      }
      difference[lag] = sum;
    }

    var runningSum = 0.0;
    difference[0] = 1;
    for (var lag = 1; lag <= maximumLag; lag++) {
      runningSum += difference[lag];
      difference[lag] = runningSum == 0
          ? 1
          : difference[lag] * lag / runningSum;
    }

    int? selectedLag;
    for (var lag = minimumLag; lag < maximumLag; lag++) {
      if (difference[lag] < threshold) {
        while (lag + 1 <= maximumLag && difference[lag + 1] < difference[lag]) {
          lag++;
        }
        selectedLag = lag;
        break;
      }
    }

    if (selectedLag == null) return null;

    final refinedLag = _parabolicInterpolation(difference, selectedLag);
    final frequency = sampleRate / refinedLag;
    final confidence = (1 - difference[selectedLag]).clamp(0.0, 1.0);

    return PitchResult(frequencyHz: frequency, confidence: confidence);
  }

  List<double> _decodePcm16(Uint8List bytes, int sampleCount) {
    final byteData = ByteData.sublistView(bytes);
    final samples = List<double>.filled(sampleCount, 0);
    var mean = 0.0;

    for (var index = 0; index < sampleCount; index++) {
      final sample = byteData.getInt16(index * 2, Endian.little) / 32768.0;
      samples[index] = sample;
      mean += sample;
    }

    mean /= sampleCount;
    for (var index = 0; index < sampleCount; index++) {
      samples[index] -= mean;
    }
    return samples;
  }

  double _rms(List<double> samples) {
    var sum = 0.0;
    for (final sample in samples) {
      sum += sample * sample;
    }
    return math.sqrt(sum / samples.length);
  }

  double _parabolicInterpolation(List<double> values, int position) {
    if (position <= 0 || position >= values.length - 1) {
      return position.toDouble();
    }

    final left = values[position - 1];
    final center = values[position];
    final right = values[position + 1];
    final denominator = 2 * (2 * center - right - left);
    if (denominator.abs() < 0.0000001) return position.toDouble();
    return position + (right - left) / denominator;
  }
}
