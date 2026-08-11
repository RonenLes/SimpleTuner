import 'package:flutter_test/flutter_test.dart';
import 'package:simple_tuner/features/tunings/tuning_catalog.dart';

void main() {
  test('contains every supported six-string tuning', () {
    expect(TuningCatalog.all, hasLength(27));
    expect(
      TuningCatalog.all.every((tuning) => tuning.notes.length == 6),
      isTrue,
    );
    expect(
      TuningCatalog.all.map((tuning) => tuning.name).toSet(),
      hasLength(27),
    );
  });

  test('standard A2 is 110 Hz', () {
    expect(TuningCatalog.standard.notes[1].frequency(), closeTo(110, 0.001));
  });
}
