import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movr/main.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('Request → Quote → Active move → Completion', (tester) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MovrApp());
    await tester.tap(find.text('I need a move'));
    await settle(tester);
    expect(find.text('Where are we moving to?'), findsOneWidget);

    // Stage 1: Recent fills the drop-off, then get a quote.
    await tester.tap(find.text('Recent'));
    await settle(tester);
    await tester.tap(find.text('Get my quote'));
    await settle(tester);

    // Stage 2: no items yet → $30 + $10 safety fee. Scan a sofa → $75.00.
    expect(find.text('Build your move'), findsOneWidget);
    expect(find.text('\$40.00'), findsOneWidget);
    await tester.tap(find.text('Scan Items with AI'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    expect(find.text('Sofa'), findsOneWidget);
    await tester.tap(find.text('Add to my move'));
    await settle(tester);
    expect(find.text('\$75.00'), findsOneWidget);

    await tester.tap(find.text('Book move'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await settle(tester);

    // Stage 3: live tracking.
    expect(find.text('Marcus · 4.9'), findsOneWidget);
    expect(find.text('BJK-992'), findsOneWidget);
    expect(find.text('Request Accepted'), findsOneWidget);

    // Let the simulated trip finish.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await settle(tester);

    // Stage 4: completion & review.
    expect(find.text('Move Complete!'), findsOneWidget);
    await tester.tap(find.text('\$10'));
    await tester.tap(find.byTooltip('5 stars'));
    await tester.pump();
    await tester.tap(find.text('Careful'));
    await tester.pump();
    await tester.ensureVisible(find.text('Submit review'));
    await tester.tap(find.text('Submit review'));
    await settle(tester);
    expect(find.text('Where are we moving to?'), findsOneWidget);
  });
}
