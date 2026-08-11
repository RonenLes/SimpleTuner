import 'package:flutter/material.dart';
import 'package:simple_tuner/features/tuner/tuner_controller.dart';
import 'package:simple_tuner/features/tuner/tuner_state.dart';
import 'package:simple_tuner/features/tunings/tuning_match.dart';

class PitchDisplay extends StatelessWidget {
  const PitchDisplay({required this.controller, super.key});

  final TunerController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        final match = state.match;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  match?.note.name ?? '--',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: _directionColor(context, match?.direction),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  match == null
                      ? '-- Hz'
                      : '${match.estimatedFundamentalHz.toStringAsFixed(2)} Hz',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  match == null
                      ? 'Play one clear, sustained string'
                      : state.lockStatus == TunerLockStatus.analyzing
                      ? 'ANALYZING...'
                      : _instruction(match.direction),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (match != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Target: string '
                    '${state.selectedTuning.notes.length - match.stringIndex} - '
                    '${match.note.name}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_signedCents(match.cents)} cents | '
                    'target ${match.targetFrequencyHz.toStringAsFixed(2)} Hz | '
                    'YIN ${(state.confidence * 100).round()}% | '
                    'spectrum ${(state.spectralConfidence * 100).round()}%',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    match.harmonicNumber > 1
                        ? 'Measured ${match.measuredFrequencyHz.toStringAsFixed(2)} Hz '
                              '(${_ordinal(match.harmonicNumber)} harmonic)'
                        : match.subharmonicDivisor > 1
                        ? 'Measured ${match.measuredFrequencyHz.toStringAsFixed(2)} Hz '
                              '(1/${match.subharmonicDivisor} subharmonic corrected)'
                        : 'Detected chromatic note: '
                              '${state.detectedNote?.name ?? match.note.name}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _instruction(TuningDirection direction) => switch (direction) {
    TuningDirection.flat => 'FLAT - TUNE UP',
    TuningDirection.inTune => 'IN TUNE',
    TuningDirection.sharp => 'SHARP - TUNE DOWN',
  };

  String _signedCents(double cents) {
    final rounded = cents.round();
    return rounded > 0 ? '+$rounded' : '$rounded';
  }

  String _ordinal(int value) => switch (value) {
    1 => '1st',
    2 => '2nd',
    3 => '3rd',
    _ => '${value}th',
  };

  Color? _directionColor(BuildContext context, TuningDirection? direction) {
    return switch (direction) {
      TuningDirection.flat => Colors.lightBlueAccent,
      TuningDirection.inTune => Theme.of(context).colorScheme.primary,
      TuningDirection.sharp => Colors.orangeAccent,
      null => null,
    };
  }
}
