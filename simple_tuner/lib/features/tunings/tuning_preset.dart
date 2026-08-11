import 'dart:math' as math;

enum TuningCategory { standard, power, open, extra, alternate }

extension TuningCategoryLabel on TuningCategory {
  String get label => switch (this) {
    TuningCategory.standard => 'Standard',
    TuningCategory.power => 'Power',
    TuningCategory.open => 'Open',
    TuningCategory.extra => 'Extra',
    TuningCategory.alternate => 'Alternate',
  };
}

class TuningNote {
  const TuningNote(this.name, this.midiNote);

  final String name;
  final int midiNote;

  double frequency({double a4Reference = 440}) {
    return a4Reference * math.pow(2, (midiNote - 69) / 12).toDouble();
  }
}

class TuningPreset {
  const TuningPreset({
    required this.name,
    required this.category,
    required this.notes,
  });

  final String name;
  final TuningCategory category;
  final List<TuningNote> notes;
}
