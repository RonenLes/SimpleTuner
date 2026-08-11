import 'package:flutter/material.dart';
import 'package:simple_tuner/features/tuner/tuner_state.dart';
import 'package:simple_tuner/features/tunings/tuning_match.dart';
import 'package:simple_tuner/features/tunings/tuning_preset.dart';

enum GuitarHeadLayout { inline, threeByThree }

class GuitarHeadSelector extends StatelessWidget {
  const GuitarHeadSelector({
    required this.tuning,
    required this.match,
    required this.lockStatus,
    required this.selectedStringIndex,
    required this.selectionMode,
    required this.layout,
    required this.onModeChanged,
    required this.onLayoutChanged,
    required this.onStringSelected,
    this.compact = false,
    super.key,
  });

  final TuningPreset tuning;
  final TuningMatch? match;
  final TunerLockStatus lockStatus;
  final int selectedStringIndex;
  final StringSelectionMode selectionMode;
  final GuitarHeadLayout layout;
  final ValueChanged<StringSelectionMode> onModeChanged;
  final ValueChanged<GuitarHeadLayout> onLayoutChanged;
  final ValueChanged<int> onStringSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        SizedBox(height: compact ? 6 : 10),
        SegmentedButton<GuitarHeadLayout>(
          segments: const [
            ButtonSegment(
              value: GuitarHeadLayout.inline,
              icon: Icon(Icons.format_align_left),
              label: Text('Inline'),
            ),
            ButtonSegment(
              value: GuitarHeadLayout.threeByThree,
              icon: Icon(Icons.grid_view),
              label: Text('3 × 3'),
            ),
          ],
          selected: {layout},
          onSelectionChanged: (selection) => onLayoutChanged(selection.first),
        ),
        SizedBox(height: compact ? 8 : 18),
        if (layout == GuitarHeadLayout.inline)
          _InlineHead(
            tuning: tuning,
            colorFor: (index) => _stringColor(context, index),
            onSelected: onStringSelected,
            compact: compact,
          )
        else
          _ThreeByThreeHead(
            tuning: tuning,
            colorFor: (index) => _stringColor(context, index),
            onSelected: onStringSelected,
            compact: compact,
          ),
      ],
    );
  }

  Color _stringColor(BuildContext context, int index) {
    final isActive =
        match?.stringIndex == index ||
        (match == null &&
            selectionMode == StringSelectionMode.manual &&
            selectedStringIndex == index);
    if (!isActive) return Theme.of(context).colorScheme.surfaceContainerHighest;
    if (lockStatus == TunerLockStatus.analyzing) return Colors.amber;
    final cents = match?.cents.abs();
    if (cents == null) return Theme.of(context).colorScheme.primaryContainer;
    if (cents <= 5) return Colors.green;
    if (cents <= 15) return Colors.amber;
    return Colors.redAccent;
  }
}

class _InlineHead extends StatelessWidget {
  const _InlineHead({
    required this.tuning,
    required this.colorFor,
    required this.onSelected,
    required this.compact,
  });
  final TuningPreset tuning;
  final Color Function(int) colorFor;
  final ValueChanged<int> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scale = compact ? 0.70 : 1.0;
    return SizedBox(
      width: 420 * scale,
      height: 430 * scale,
      child: Stack(
        children: [
          Positioned(
            left: 145 * scale,
            top: 0,
            width: 255 * scale,
            height: 430 * scale,
            child: Image.asset(
              'assets/images/headstocks/inline_headstock_ui.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          for (var peg = 0; peg < 6; peg++)
            Positioned(
              left: 55 * scale,
              top: const [41.0, 85.0, 131.0, 179.0, 225.0, 269.0][peg] * scale,
              child: _StringButton(
                number: peg + 1,
                note: tuning.notes[5 - peg].name,
                color: colorFor(5 - peg),
                onPressed: () => onSelected(5 - peg),
                compact: compact,
              ),
            ),
        ],
      ),
    );
  }
}

class _ThreeByThreeHead extends StatelessWidget {
  const _ThreeByThreeHead({
    required this.tuning,
    required this.colorFor,
    required this.onSelected,
    required this.compact,
  });
  final TuningPreset tuning;
  final Color Function(int) colorFor;
  final ValueChanged<int> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scale = compact ? 0.76 : 1.0;
    return SizedBox(
      width: 370 * scale,
      height: 290 * scale,
      child: Stack(
        children: [
          Positioned(
            left: 98 * scale,
            top: 0,
            width: 174 * scale,
            height: 290 * scale,
            child: Image.asset(
              'assets/images/headstocks/three_by_three_headstock_ui.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          for (var peg = 0; peg < 3; peg++) ...[
            Positioned(
              left: 20 * scale,
              top: const [52.0, 100.0, 149.0][peg] * scale,
              child: _StringButton(
                number: 4 + peg,
                note: tuning.notes[2 - peg].name,
                color: colorFor(2 - peg),
                onPressed: () => onSelected(2 - peg),
                compact: compact,
              ),
            ),
            Positioned(
              right: 20 * scale,
              top: const [52.0, 100.0, 149.0][peg] * scale,
              child: _StringButton(
                number: 3 - peg,
                note: tuning.notes[3 + peg].name,
                color: colorFor(3 + peg),
                onPressed: () => onSelected(3 + peg),
                compact: compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StringButton extends StatelessWidget {
  const _StringButton({
    required this.number,
    required this.note,
    required this.color,
    required this.onPressed,
    this.compact = false,
  });
  final int number;
  final String note;
  final Color color;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'String $number, $note',
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onPressed,
        child: Container(
          width: compact ? 54 : 68,
          height: compact ? 30 : 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$number', style: Theme.of(context).textTheme.labelSmall),
              SizedBox(width: compact ? 3 : 6),
              Text(
                note,
                style:
                    (compact
                            ? Theme.of(context).textTheme.bodyMedium
                            : Theme.of(context).textTheme.titleMedium)
                        ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
