import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Load the real app fonts so text measures as it does on device; the
/// default test font is wider and would report false overflows.
Future<void> loadAppFonts() async {
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
