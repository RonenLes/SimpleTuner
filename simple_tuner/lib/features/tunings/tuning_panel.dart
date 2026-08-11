import 'package:flutter/material.dart';
import 'package:simple_tuner/features/tunings/tuning_catalog.dart';
import 'package:simple_tuner/features/tunings/tuning_preset.dart';

class TuningPanel extends StatelessWidget {
  const TuningPanel({
    required this.selectedTuning,
    required this.onSelected,
    super.key,
  });

  final TuningPreset selectedTuning;
  final ValueChanged<TuningPreset> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tunings',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose a target setup',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  for (final category in TuningCategory.values)
                    ExpansionTile(
                      initiallyExpanded: category == selectedTuning.category,
                      title: Text(category.label),
                      children: [
                        for (final tuning in TuningCatalog.all.where(
                          (item) => item.category == category,
                        ))
                          ListTile(
                            selected: identical(tuning, selectedTuning),
                            selectedTileColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.5),
                            leading: Icon(
                              identical(tuning, selectedTuning)
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                            ),
                            title: Text(tuning.name),
                            subtitle: Text(
                              tuning.notes.map((note) => note.name).join('  '),
                            ),
                            onTap: () => onSelected(tuning),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
