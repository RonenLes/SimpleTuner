import 'package:flutter/material.dart';
import 'package:simple_tuner/features/tunings/tuning_match.dart';

class TuningMeter extends StatelessWidget {
  const TuningMeter({required this.match, super.key});

  final TuningMatch? match;

  @override
  Widget build(BuildContext context) {
    final cents = match?.cents.clamp(-50.0, 50.0) ?? 0.0;
    final alignment = cents / 50;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('FLAT'), Text('IN TUNE'), Text('SHARP')],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.lightBlueAccent,
                          Colors.greenAccent,
                          Colors.orangeAccent,
                        ],
                      ),
                    ),
                  ),
                  const Align(
                    child: SizedBox(
                      height: 24,
                      child: VerticalDivider(width: 2, thickness: 2),
                    ),
                  ),
                  AnimatedAlign(
                    alignment: Alignment(alignment, 0),
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOut,
                    child: Icon(
                      Icons.arrow_drop_down,
                      size: 42,
                      color: match == null
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('-50'), Text('0'), Text('+50 cents')],
            ),
          ],
        ),
      ),
    );
  }
}
