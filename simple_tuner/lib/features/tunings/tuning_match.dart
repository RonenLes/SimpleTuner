import 'package:simple_tuner/features/tunings/tuning_preset.dart';

enum TuningDirection { flat, inTune, sharp }

enum StringSelectionMode { automatic, manual }

class TuningMatch {
  const TuningMatch({
    required this.stringIndex,
    required this.note,
    required this.targetFrequencyHz,
    required this.measuredFrequencyHz,
    required this.estimatedFundamentalHz,
    required this.harmonicNumber,
    required this.subharmonicDivisor,
    required this.cents,
    required this.direction,
  });

  final int stringIndex;
  final TuningNote note;
  final double targetFrequencyHz;
  final double measuredFrequencyHz;
  final double estimatedFundamentalHz;
  final int harmonicNumber;
  final int subharmonicDivisor;
  final double cents;
  final TuningDirection direction;
}
