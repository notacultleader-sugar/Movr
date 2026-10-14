import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movr/main.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('Sign up → go online → accept → complete → earnings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MovrApp());
    await tester.tap(find.text('Drive with movr'));
    await settle(tester);

    // Sign-up: About you and Vehicle are prefilled.
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('Vehicle type'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    // Documents: Continue stays disabled until all four are uploaded.
    for (final doc in [
      'Driver\'s licence',
      'Vehicle insurance',
      'Vehicle registration',
      'Photo of your vehicle',
    ]) {
      await tester.tap(find.text(doc));
      await tester.pump();
    }
    await tester.tap(find.text('Continue'));
    await settle(tester);

    await tester.tap(find.text('I can safely lift 50+ lb'));
    await tester.tap(find.text('I consent to a background check'));
    await tester.pump();
    await tester.tap(find.text('Submit application'));
    await settle(tester);
    expect(find.text('Application submitted'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('You\'re approved, Jordan!'), findsOneWidget);
    await tester.tap(find.text('Start driving'));
    await settle(tester);

    // Go online and receive a request.
    expect(find.text('You\'re offline'), findsOneWidget);
    await tester.tap(find.text('Go online'));
    await tester.pump(const Duration(seconds: 4));
    await settle(tester);
    expect(find.text('New Haul request'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    await settle(tester);

    // Drive to pickup, load, drive to drop-off, complete.
    await tester.pump(const Duration(seconds: 7));
    await tester.tap(find.text('I\'ve arrived at pickup'));
    await tester.pump();
    await tester.tap(find.text('Take a photo of the load'));
    await tester.tap(find.text('Items loaded and strapped down'));
    await tester.pump();
    await tester.tap(find.text('Start trip'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 7));
    await tester.tap(find.text('I\'ve arrived at drop-off'));
    await tester.pump();
    await tester.tap(find.text('Complete move'));
    await settle(tester);

    // Sofa job: $52.50 fare − $13.13 fee + $10 tip.
    expect(find.text('Move complete'), findsOneWidget);
    expect(find.text('\$49.37'), findsWidgets);
    await tester.tap(find.text('Back to the map'));
    await settle(tester);
    expect(find.text('\$49.37'), findsOneWidget); // today's earnings badge

    // Earnings screen and cash-out.
    await tester.tap(find.text('Go offline'));
    await tester.pump();
    await tester.tap(find.text('\$49.37'));
    await settle(tester);
    expect(find.text('Today\'s moves'), findsOneWidget);
    await tester.tap(find.text('Cash out'));
    await tester.pump();
    expect(find.textContaining('sent to bank'), findsOneWidget);
  });
}
