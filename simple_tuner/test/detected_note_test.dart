import 'package:flutter_test/flutter_test.dart';
import 'package:simple_tuner/features/pitch_detection/detected_note.dart';

void main() {
  test('converts frequencies to independent chromatic notes', () {
    expect(DetectedNote.fromFrequency(82.41).name, 'E2');
    expect(DetectedNote.fromFrequency(110).name, 'A2');
    expect(DetectedNote.fromFrequency(146.83).name, 'D3');
    expect(DetectedNote.fromFrequency(329.63).name, 'E4');
  });
}
