import 'dart:math' as math;

class DetectedNote {
  const DetectedNote({
    required this.name,
    required this.midiNote,
    required this.frequencyHz,
    required this.centsFromNote,
  });

  static const _noteNames = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  final String name;
  final int midiNote;
  final double frequencyHz;
  final double centsFromNote;

  static DetectedNote fromFrequency(double frequencyHz) {
    final exactMidi = 69 + 12 * (math.log(frequencyHz / 440) / math.ln2);
    final midiNote = exactMidi.round();
    final octave = (midiNote ~/ 12) - 1;
    final noteName = _noteNames[midiNote % 12];
    final noteFrequency = 440 * math.pow(2, (midiNote - 69) / 12).toDouble();
    final cents = 1200 * (math.log(frequencyHz / noteFrequency) / math.ln2);

    return DetectedNote(
      name: '$noteName$octave',
      midiNote: midiNote,
      frequencyHz: noteFrequency,
      centsFromNote: cents,
    );
  }
}
