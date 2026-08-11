import 'dart:math' as math;

import 'package:simple_tuner/features/tunings/tuning_match.dart';
import 'package:simple_tuner/features/tunings/tuning_preset.dart';

class TuningMatcher {
  const TuningMatcher({
    this.inTuneToleranceCents = 5,
    this.maximumHarmonic = 4,
    this.harmonicPenaltyCents = 3,
  });

  final double inTuneToleranceCents;
  final int maximumHarmonic;
  final double harmonicPenaltyCents;

  TuningMatch match({
    required double frequencyHz,
    required TuningPreset tuning,
    int? stringIndex,
  }) {
    final candidate = stringIndex == null
        ? _closestCandidate(frequencyHz, tuning)
        : _closestHarmonic(
            frequencyHz: frequencyHz,
            tuning: tuning,
            stringIndex: stringIndex,
          );
    final note = tuning.notes[candidate.stringIndex];
    final targetFrequency = note.frequency();
    final estimatedFundamental =
        frequencyHz * candidate.subharmonicDivisor / candidate.harmonicNumber;
    final cents = centsBetween(estimatedFundamental, targetFrequency);
    final direction = cents.abs() <= inTuneToleranceCents
        ? TuningDirection.inTune
        : cents < 0
        ? TuningDirection.flat
        : TuningDirection.sharp;

    return TuningMatch(
      stringIndex: candidate.stringIndex,
      note: note,
      targetFrequencyHz: targetFrequency,
      measuredFrequencyHz: frequencyHz,
      estimatedFundamentalHz: estimatedFundamental,
      harmonicNumber: candidate.harmonicNumber,
      subharmonicDivisor: candidate.subharmonicDivisor,
      cents: cents,
      direction: direction,
    );
  }

  double centsBetween(double frequencyHz, double targetFrequencyHz) {
    return 1200 * (math.log(frequencyHz / targetFrequencyHz) / math.ln2);
  }

  _MatchCandidate _closestCandidate(double frequencyHz, TuningPreset tuning) {
    var best = const _MatchCandidate(
      stringIndex: 0,
      harmonicNumber: 1,
      subharmonicDivisor: 1,
      score: double.infinity,
    );

    for (
      var stringIndex = 0;
      stringIndex < tuning.notes.length;
      stringIndex++
    ) {
      final candidate = _closestHarmonic(
        frequencyHz: frequencyHz,
        tuning: tuning,
        stringIndex: stringIndex,
      );
      if (candidate.score < best.score) best = candidate;
    }
    return best;
  }

  _MatchCandidate _closestHarmonic({
    required double frequencyHz,
    required TuningPreset tuning,
    required int stringIndex,
  }) {
    final targetFrequency = tuning.notes[stringIndex].frequency();
    var best = _MatchCandidate(
      stringIndex: stringIndex,
      harmonicNumber: 1,
      subharmonicDivisor: 1,
      score: double.infinity,
    );

    for (var harmonic = 1; harmonic <= maximumHarmonic; harmonic++) {
      final harmonicFrequency = targetFrequency * harmonic;
      final distance = centsBetween(frequencyHz, harmonicFrequency).abs();
      final score = distance + (harmonic - 1) * harmonicPenaltyCents;
      if (score < best.score) {
        best = _MatchCandidate(
          stringIndex: stringIndex,
          harmonicNumber: harmonic,
          subharmonicDivisor: 1,
          score: score,
        );
      }
    }

    for (var divisor = 2; divisor <= maximumHarmonic; divisor++) {
      final subharmonicFrequency = targetFrequency / divisor;
      final distance = centsBetween(frequencyHz, subharmonicFrequency).abs();
      // Subharmonic correction is less certain than observing a real harmonic,
      // so give it a larger penalty when two interpretations are tied.
      final score = distance + (divisor - 1) * harmonicPenaltyCents * 2;
      if (score < best.score) {
        best = _MatchCandidate(
          stringIndex: stringIndex,
          harmonicNumber: 1,
          subharmonicDivisor: divisor,
          score: score,
        );
      }
    }
    return best;
  }
}

class _MatchCandidate {
  const _MatchCandidate({
    required this.stringIndex,
    required this.harmonicNumber,
    required this.subharmonicDivisor,
    required this.score,
  });

  final int stringIndex;
  final int harmonicNumber;
  final int subharmonicDivisor;
  final double score;
}
