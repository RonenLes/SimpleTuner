import 'package:simple_tuner/features/pitch_detection/detected_note.dart';
import 'package:simple_tuner/features/tunings/tuning_catalog.dart';
import 'package:simple_tuner/features/tunings/tuning_match.dart';
import 'package:simple_tuner/features/tunings/tuning_preset.dart';

enum TunerLockStatus { waiting, analyzing, locked }

class TunerState {
  const TunerState({
    this.frequencyHz,
    this.confidence = 0,
    this.selectedTuning = TuningCatalog.standard,
    this.selectionMode = StringSelectionMode.automatic,
    this.selectedStringIndex = 0,
    this.match,
    this.detectedNote,
    this.spectralConfidence = 0,
    this.lockStatus = TunerLockStatus.waiting,
  });

  final double? frequencyHz;
  final double confidence;
  final TuningPreset selectedTuning;
  final StringSelectionMode selectionMode;
  final int selectedStringIndex;
  final TuningMatch? match;
  final DetectedNote? detectedNote;
  final double spectralConfidence;
  final TunerLockStatus lockStatus;
}
