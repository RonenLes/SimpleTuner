import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:simple_tuner/features/tunings/tuning_match.dart';

class NeedleTuningMeter extends StatelessWidget {
  const NeedleTuningMeter({
    required this.match,
    this.compact = false,
    super.key,
  });

  final TuningMatch? match;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cents = match?.cents.clamp(-50.0, 50.0) ?? 0.0;

    return Column(
      children: [
        Text(
          match == null
              ? 'Play a string'
              : switch (match!.direction) {
                  TuningDirection.flat => 'TUNE UP',
                  TuningDirection.inTune => 'IN TUNE',
                  TuningDirection.sharp => 'TUNE DOWN',
                },
          style:
              (compact
                      ? Theme.of(context).textTheme.titleLarge
                      : Theme.of(context).textTheme.headlineSmall)
                  ?.copyWith(
                    color: _statusColor(match),
                    fontWeight: FontWeight.bold,
                  ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(end: cents),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => SizedBox(
            height: compact ? 150 : 230,
            width: double.infinity,
            child: CustomPaint(
              painter: _NeedleMeterPainter(
                cents: value,
                color: _statusColor(match),
                surfaceColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHigh,
                textColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(TuningMatch? value) {
    if (value == null) return Colors.white54;
    if (value.cents.abs() <= 5) return Colors.greenAccent;
    if (value.cents.abs() <= 15) return Colors.amber;
    return Colors.redAccent;
  }
}

class _NeedleMeterPainter extends CustomPainter {
  const _NeedleMeterPainter({
    required this.cents,
    required this.color,
    required this.surfaceColor,
    required this.textColor,
  });

  final double cents;
  final Color color;
  final Color surfaceColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.88);
    final radius = math.min(size.width * 0.39, size.height * 0.72);
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final arcPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 14;
    canvas.drawArc(arcRect, math.pi, math.pi, false, arcPaint);

    for (var tick = -50; tick <= 50; tick += 5) {
      final angle = math.pi + ((tick + 50) / 100) * math.pi;
      final isMajor = tick % 10 == 0;
      final outside = Offset(
        center.dx + math.cos(angle) * (radius + 2),
        center.dy + math.sin(angle) * (radius + 2),
      );
      final inside = Offset(
        center.dx + math.cos(angle) * (radius - (isMajor ? 18 : 10)),
        center.dy + math.sin(angle) * (radius - (isMajor ? 18 : 10)),
      );
      canvas.drawLine(
        inside,
        outside,
        Paint()
          ..color = tick == 0 ? Colors.greenAccent : textColor
          ..strokeWidth = tick == 0 ? 3 : 1.5,
      );
    }

    final needleAngle = math.pi + ((cents + 50) / 100) * math.pi;
    final needleEnd = Offset(
      center.dx + math.cos(needleAngle) * (radius - 28),
      center.dy + math.sin(needleAngle) * (radius - 28),
    );
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = color
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 13, Paint()..color = color);
    canvas.drawCircle(center, 5, Paint()..color = Colors.black87);

    _drawLabel(canvas, size, '-50', Offset(center.dx - radius, center.dy + 18));
    _drawLabel(canvas, size, '0', Offset(center.dx, center.dy - radius - 20));
    _drawLabel(canvas, size, '+50', Offset(center.dx + radius, center.dy + 18));
  }

  void _drawLabel(Canvas canvas, Size size, String label, Offset position) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: textColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(position.dx - painter.width / 2, position.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _NeedleMeterPainter oldDelegate) {
    return oldDelegate.cents != cents || oldDelegate.color != color;
  }
}
