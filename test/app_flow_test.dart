import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movr/main.dart';

/// Load the real app fonts so text measures as it does on device; the
/// default test font is wider and would report false overflows.
Future<void> _loadFonts() async {
  const families = {
    'Montserrat': ['SemiBold', 'Bold', 'ExtraBold'],
    'Inter': ['Regular', 'Medium', 'SemiBold', 'Bold'],
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final weight in entry.value) {
      loader.addFont(rootBundle.load('assets/fonts/${entry.key}-$weight.ttf'));
    }
    await loader.load();
  }
}

/// The home map animates forever, so pumpAndSettle never settles. Pump
/// long enough for sheets and page transitions to finish instead.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('Request → Quote → Active move → Completion', (tester) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MovrApp());
    expect(find.text('Where are we moving to?'), findsOneWidget);

    // Stage 1: Recent fills the drop-off, then get a quote.
    await tester.tap(find.text('Recent'));
    await settle(tester);
    await tester.tap(find.text('Get my quote'));
    await settle(tester);

    // Stage 2: no items yet → $45 + $10 safety fee. Scan a sofa → $62.50.
    expect(find.text('Build your move'), findsOneWidget);
    expect(find.text('\$55.00'), findsOneWidget);
    await tester.tap(find.text('Scan Items with AI'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    expect(find.text('Sofa'), findsOneWidget);
    await tester.tap(find.text('Add to my move'));
    await settle(tester);
    expect(find.text('\$62.50'), findsOneWidget);

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
