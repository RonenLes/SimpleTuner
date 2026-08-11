enum AudioInputStatus { idle, requestingPermission, listening, denied, error }

class AudioInputState {
  const AudioInputState({
    this.status = AudioInputStatus.idle,
    this.bytesReceived = 0,
    this.audioLevel = 0,
    this.sampleRate = 44100,
    this.errorMessage,
  });

  final AudioInputStatus status;
  final int bytesReceived;
  final double audioLevel;
  final int sampleRate;
  final String? errorMessage;

  bool get isListening => status == AudioInputStatus.listening;

  AudioInputState copyWith({
    AudioInputStatus? status,
    int? bytesReceived,
    double? audioLevel,
    int? sampleRate,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AudioInputState(
      status: status ?? this.status,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      audioLevel: audioLevel ?? this.audioLevel,
      sampleRate: sampleRate ?? this.sampleRate,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
