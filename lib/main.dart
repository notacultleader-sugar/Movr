import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'theme.dart';

void main() => runApp(const MovrApp());

class MovrApp extends StatelessWidget {
  const MovrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'movr',
      debugShowCheckedModeBanner: false,
      theme: buildMovrTheme(),
      builder: (context, child) => _PhoneFrame(child: child!),
      home: const WelcomeScreen(),
    );
  }
}

/// On wide screens (desktop browser) show the app inside a phone-sized frame
/// so the web preview looks like the mobile app. On phones it is a no-op.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width < 600) return child;

    final height = (media.size.height - 48).clamp(560.0, 880.0);
    final size = Size(height * 0.47, height);
    return ColoredBox(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.black, width: 8),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 40)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: MediaQuery(
              data: media.copyWith(
                size: Size(size.width - 16, size.height - 16),
                padding: EdgeInsets.zero,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
