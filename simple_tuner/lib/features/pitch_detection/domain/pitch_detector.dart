import 'dart:typed_data';

import 'package:simple_tuner/features/pitch_detection/domain/pitch_result.dart';

abstract interface class PitchDetector {
  PitchResult? detect(Uint8List pcm16Bytes);
}
