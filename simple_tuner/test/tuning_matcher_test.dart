import 'package:flutter_test/flutter_test.dart';
import 'package:simple_tuner/features/tunings/tuning_catalog.dart';
import 'package:simple_tuner/features/tunings/tuning_match.dart';
import 'package:simple_tuner/features/tunings/tuning_matcher.dart';

void main() {
  const matcher = TuningMatcher();

  test('matches 82.41 Hz to standard E2', () {
    final match = matcher.match(
      frequencyHz: 82.41,
      tuning: TuningCatalog.standard,
    );

    expect(match.note.name, 'E2');
    expect(match.stringIndex, 0);
    expect(match.direction, TuningDirection.inTune);
    expect(match.cents, closeTo(0, 0.1));
    expect(match.harmonicNumber, 1);
    expect(match.subharmonicDivisor, 1);
  });

  test('marks a low frequency flat and a high frequency sharp', () {
    final flat = matcher.match(
      frequencyHz: 81,
      tuning: TuningCatalog.standard,
      stringIndex: 0,
    );
    final sharp = matcher.match(
      frequencyHz: 84,
      tuning: TuningCatalog.standard,
      stringIndex: 0,
    );

    expect(flat.direction, TuningDirection.flat);
    expect(flat.cents, lessThan(-5));
    expect(sharp.direction, TuningDirection.sharp);
    expect(sharp.cents, greaterThan(5));
  });

  test('manual mode matches the requested string', () {
    final match = matcher.match(
      frequencyHz: 110,
      tuning: TuningCatalog.standard,
      stringIndex: 1,
    );

    expect(match.note.name, 'A2');
    expect(match.stringIndex, 1);
    expect(match.direction, TuningDirection.inTune);
  });

  test('maps the second harmonic of low E back to E2', () {
    final match = matcher.match(
      frequencyHz: 164.42,
      tuning: TuningCatalog.standard,
    );

    expect(match.note.name, 'E2');
    expect(match.harmonicNumber, 2);
    expect(match.estimatedFundamentalHz, closeTo(82.21, 0.01));
    expect(match.cents, closeTo(-4.2, 0.2));
  });

  test('prefers high E fundamental over low E fourth harmonic', () {
    final match = matcher.match(
      frequencyHz: 329.63,
      tuning: TuningCatalog.standard,
    );

    expect(match.note.name, 'E4');
    expect(match.harmonicNumber, 1);
  });

  test('maps the measured B2 subharmonic back to the B3 string', () {
    final match = matcher.match(
      frequencyHz: 123.64,
      tuning: TuningCatalog.standard,
    );

    expect(match.note.name, 'B3');
    expect(match.stringIndex, 4);
    expect(match.subharmonicDivisor, 2);
    expect(match.estimatedFundamentalHz, closeTo(247.28, 0.01));
    expect(match.cents, closeTo(2.4, 0.2));
    expect(match.direction, TuningDirection.inTune);
  });

  test('manual G3 corrects the exact 98.42 Hz screenshot reading', () {
    final match = matcher.match(
      frequencyHz: 98.42,
      tuning: TuningCatalog.standard,
      stringIndex: 3,
    );

    expect(match.note.name, 'G3');
    expect(match.subharmonicDivisor, 2);
    expect(match.estimatedFundamentalHz, closeTo(196.84, 0.01));
    expect(match.cents, closeTo(7.4, 0.2));
    expect(match.direction, TuningDirection.sharp);
  });
}
