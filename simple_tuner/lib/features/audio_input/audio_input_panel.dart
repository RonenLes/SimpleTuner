import 'package:flutter/material.dart';
import 'package:simple_tuner/features/audio_input/audio_input_controller.dart';
import 'package:simple_tuner/features/audio_input/audio_input_state.dart';

class AudioInputPanel extends StatelessWidget {
  const AudioInputPanel({required this.controller, super.key});

  final AudioInputController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      state.isListening ? Icons.mic : Icons.mic_none,
                      color: state.isListening
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusLabel(state.status),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'PCM16 mono · ${state.sampleRate} Hz · '
                  '${state.bytesReceived} bytes received',
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Audio level'),
                    Text('${(state.audioLevel * 100).round()}%'),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: state.audioLevel),
                    duration: const Duration(milliseconds: 80),
                    builder: (context, level, _) {
                      return LinearProgressIndicator(
                        value: level,
                        minHeight: 14,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        color: _meterColor(context, level),
                      );
                    },
                  ),
                ),
                if (state.errorMessage case final message?) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed:
                      state.status == AudioInputStatus.requestingPermission
                      ? null
                      : state.isListening
                      ? controller.stop
                      : controller.start,
                  icon: Icon(state.isListening ? Icons.stop : Icons.mic),
                  label: Text(
                    state.isListening ? 'Stop microphone' : 'Start microphone',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _statusLabel(AudioInputStatus status) => switch (status) {
    AudioInputStatus.idle => 'Microphone is off',
    AudioInputStatus.requestingPermission => 'Requesting permission…',
    AudioInputStatus.listening => 'Receiving microphone audio',
    AudioInputStatus.denied => 'Microphone permission denied',
    AudioInputStatus.error => 'Microphone error',
  };

  Color _meterColor(BuildContext context, double level) {
    if (level > 0.85) return Theme.of(context).colorScheme.error;
    if (level > 0.65) return Colors.amber;
    return Theme.of(context).colorScheme.primary;
  }
}
