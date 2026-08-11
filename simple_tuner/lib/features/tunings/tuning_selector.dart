import 'package:flutter/material.dart';
import 'package:simple_tuner/features/tunings/tuning_catalog.dart';
import 'package:simple_tuner/features/tunings/tuning_match.dart';
import 'package:simple_tuner/features/tunings/tuning_preset.dart';

class TuningSelector extends StatelessWidget {
  const TuningSelector({
    required this.selectedTuning,
    required this.selectionMode,
    required this.selectedStringIndex,
    required this.onTuningChanged,
    required this.onModeChanged,
    required this.onStringSelected,
    super.key,
  });

  final TuningPreset selectedTuning;
  final StringSelectionMode selectionMode;
  final int selectedStringIndex;
  final ValueChanged<TuningPreset> onTuningChanged;
  final ValueChanged<StringSelectionMode> onModeChanged;
  final ValueChanged<int> onStringSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<TuningPreset>(
              initialValue: selectedTuning,
              decoration: const InputDecoration(
                labelText: 'Tuning',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final category in TuningCategory.values)
                  for (final tuning in TuningCatalog.all.where(
                    (item) => item.category == category,
                  ))
                    DropdownMenuItem(
                      value: tuning,
                      child: Text('${category.label} - ${tuning.name}'),
                    ),
              ],
              onChanged: (value) {
                if (value != null) onTuningChanged(value);
              },
            ),
            const SizedBox(height: 16),
            SegmentedButton<StringSelectionMode>(
              segments: const [
                ButtonSegment(
                  value: StringSelectionMode.automatic,
                  icon: Icon(Icons.auto_awesome),
                  label: Text('Auto'),
                ),
                ButtonSegment(
                  value: StringSelectionMode.manual,
                  icon: Icon(Icons.touch_app),
                  label: Text('Manual'),
                ),
              ],
              selected: {selectionMode},
              onSelectionChanged: (selection) => onModeChanged(selection.first),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (
                  var index = 0;
                  index < selectedTuning.notes.length;
                  index++
                )
                  ChoiceChip(
                    selected: index == selectedStringIndex,
                    avatar: CircleAvatar(
                      child: Text('${selectedTuning.notes.length - index}'),
                    ),
                    label: Text(selectedTuning.notes[index].name),
                    onSelected: (_) => onStringSelected(index),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
