import 'package:athlete_os/src/features/training/presentation/figma_score_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Figma reps control edits numeric scores without going below zero',
      (tester) async {
    var value = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => FigmaScoreCounter(
            label: 'Extra reps',
            value: value,
            onChanged: (next) => setState(() => value = next),
          ),
        ),
      ),
    ));

    expect(find.text('Extra reps'), findsOneWidget);
    expect(value, 0);
    await tester.tap(find.byTooltip('Increase Extra reps'));
    await tester.pump();
    expect(value, 1);
    await tester.tap(find.byTooltip('Decrease Extra reps'));
    await tester.pump();
    expect(value, 0);
    await tester.tap(find.byTooltip('Decrease Extra reps'));
    await tester.pump();
    expect(value, 0);
    expect(find.byKey(const Key('figma-score-counter-value')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
