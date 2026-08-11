import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_tuner/app/simple_tuner_app.dart';

void main() {
  testWidgets('shows the redesigned tuner workspace', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SimpleTunerApp());

    expect(find.text('Simple Tuner'), findsOneWidget);
    expect(find.text('Tunings'), findsOneWidget);
    expect(find.text('Auto'), findsOneWidget);
    expect(find.text('Manual'), findsOneWidget);
    expect(find.text('Inline'), findsOneWidget);
    expect(find.text('3 × 3'), findsOneWidget);
    expect(find.text('Start tuning'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('opens tunings from the left on a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SimpleTunerApp());
    await tester.tap(find.byTooltip('Open tunings'));
    await tester.pumpAndSettle();

    expect(find.text('Tunings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
