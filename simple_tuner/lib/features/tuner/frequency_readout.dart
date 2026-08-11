import 'package:flutter/material.dart';
import 'package:simple_tuner/features/tunings/tuning_match.dart';
import 'package:simple_tuner/features/tunings/tuning_preset.dart';

class FrequencyReadout extends StatelessWidget {
  const FrequencyReadout({
    required this.match,
    required this.tuning,
    this.compact = false,
    super.key,
  });

  final TuningMatch? match;
  final TuningPreset tuning;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(
              match == null
                  ? '-- Hz'
                  : '${match!.estimatedFundamentalHz.toStringAsFixed(2)} Hz',
              style: compact
                  ? Theme.of(context).textTheme.titleLarge
                  : Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              match == null
                  ? 'Waiting for a note'
                  : '${_signed(match!.cents)} cents from ${match!.note.name}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Target frequencies',
          onPressed: () => _showFrequencies(context),
          icon: const Icon(Icons.info_outline),
          visualDensity: compact ? VisualDensity.compact : null,
        ),
      ],
    );
  }

  String _signed(double value) {
    final rounded = value.round();
    return rounded > 0 ? '+$rounded' : '$rounded';
  }

  Future<void> _showFrequencies(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${tuning.name} target frequencies'),
        content: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('String')),
              DataColumn(label: Text('Note')),
              DataColumn(label: Text('Frequency')),
            ],
            rows: [
              for (var index = 0; index < tuning.notes.length; index++)
                DataRow(
                  cells: [
                    DataCell(Text('${tuning.notes.length - index}')),
                    DataCell(Text(tuning.notes[index].name)),
                    DataCell(
                      Text(
                        '${tuning.notes[index].frequency().toStringAsFixed(2)} Hz',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
