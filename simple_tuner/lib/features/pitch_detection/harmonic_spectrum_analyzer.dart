import 'dart:math' as math;
import 'dart:typed_data';

class HarmonicSpectrumResult {
  const HarmonicSpectrumResult({
    required this.bestIndex,
    required this.confidence,
    required this.scores,
  });

  final int bestIndex;
  final double confidence;
  final List<double> scores;
}

/// Scores possible fundamentals by measuring energy at their harmonic series.
class HarmonicSpectrumAnalyzer {
  const HarmonicSpectrumAnalyzer({
    this.harmonicCount = 4,
    this.detuneOffsetsCents = const [-40, 0, 40],
  });

  final int harmonicCount;
  final List<double> detuneOffsetsCents;

  HarmonicSpectrumResult? analyze({
    required Uint8List pcm16Bytes,
    required int sampleRate,
    required List<double> fundamentalFrequencies,
  }) {
    if (pcm16Bytes.length < 4 || fundamentalFrequencies.isEmpty) return null;

    final samples = _decodeAndWindow(pcm16Bytes);
    final scores = <double>[];

    for (final fundamental in fundamentalFrequencies) {
      var score = 0.0;
      for (var harmonic = 1; harmonic <= harmonicCount; harmonic++) {
        final centerFrequency = fundamental * harmonic;
        if (centerFrequency >= sampleRate / 2) break;

        var strongestPower = 0.0;
        for (final cents in detuneOffsetsCents) {
          final frequency =
              centerFrequency * math.pow(2, cents / 1200).toDouble();
          strongestPower = math.max(
            strongestPower,
            _goertzelPower(samples, frequency, sampleRate),
          );
        }

        // Square root reduces domination by one unusually loud partial. Lower
        // harmonics still receive more weight than upper harmonics.
        score += math.sqrt(strongestPower) / harmonic;
      }
      scores.add(score);
    }

    var bestIndex = 0;
    var bestScore = scores.first;
    var secondBestScore = 0.0;
    for (var index = 1; index < scores.length; index++) {
      final score = scores[index];
      if (score > bestScore) {
        secondBestScore = bestScore;
        bestScore = score;
        bestIndex = index;
      } else if (score > secondBestScore) {
        secondBestScore = score;
      }
    }

    if (bestScore <= 0) return null;
    final confidence = bestScore / (bestScore + secondBestScore);
    return HarmonicSpectrumResult(
      bestIndex: bestIndex,
      confidence: confidence.clamp(0.0, 1.0),
      scores: List.unmodifiable(scores),
    );
  }

  List<double> _decodeAndWindow(Uint8List bytes) {
    final sampleCount = bytes.length ~/ 2;
    final data = ByteData.sublistView(bytes);
    final samples = List<double>.filled(sampleCount, 0);
    var mean = 0.0;

    for (var index = 0; index < sampleCount; index++) {
      final sample = data.getInt16(index * 2, Endian.little) / 32768.0;
      samples[index] = sample;
      mean += sample;
    }
    mean /= sampleCount;

    for (var index = 0; index < sampleCount; index++) {
      final hann = sampleCount == 1
          ? 1.0
          : 0.5 - 0.5 * math.cos(2 * math.pi * index / (sampleCount - 1));
      samples[index] = (samples[index] - mean) * hann;
    }
    return samples;
  }

  double _goertzelPower(
    List<double> samples,
    double frequency,
    int sampleRate,
  ) {
    final coefficient = 2 * math.cos(2 * math.pi * frequency / sampleRate);
    var previous = 0.0;
    var previousPrevious = 0.0;

    for (final sample in samples) {
      final current = sample + coefficient * previous - previousPrevious;
      previousPrevious = previous;
      previous = current;
    }

    return previous * previous +
        previousPrevious * previousPrevious -
        coefficient * previous * previousPrevious;
  }
}
