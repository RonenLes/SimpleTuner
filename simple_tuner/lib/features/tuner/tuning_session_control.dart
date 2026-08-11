import 'package:flutter/material.dart';
import 'package:simple_tuner/features/audio_input/audio_input_controller.dart';
import 'package:simple_tuner/features/audio_input/audio_input_state.dart';

class TuningSessionControl extends StatelessWidget {
  const TuningSessionControl({required this.controller, super.key});

  final AudioInputController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        if (!state.isListening) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: state.status == AudioInputStatus.requestingPermission
                    ? null
                    : controller.start,
                icon: const Icon(Icons.mic),
                label: Text(
                  state.status == AudioInputStatus.requestingPermission
                      ? 'Requesting microphone...'
                      : 'Start tuning',
                ),
              ),
              if (state.status == AudioInputStatus.denied ||
                  state.status == AudioInputStatus.error) ...[
                const SizedBox(height: 8),
                Text(
                  state.errorMessage ?? 'Microphone permission was denied.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          );
        }

        return Row(
          children: [
            const Icon(Icons.mic, color: Colors.greenAccent),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: state.audioLevel,
                  minHeight: 14,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  color: state.audioLevel > 0.85
                      ? Colors.redAccent
                      : state.audioLevel > 0.65
                      ? Colors.amber
                      : Colors.greenAccent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('${(state.audioLevel * 100).round()}%'),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: controller.stop,
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            ),
          ],
        );
      },
    );
  }
}
