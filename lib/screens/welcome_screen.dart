import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'driver/signup_screen.dart';
import 'request_screen.dart';

/// First screen: book a move, or sign up to drive.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MovrLogo(height: 44),
              const SizedBox(height: 28),
              Text('Muscle and wheels,\non demand.', style: text.headlineLarge),
              const SizedBox(height: 10),
              Text(
                'A truck and a driver for your couch, your Marketplace find or your studio move. Or put your own truck to work.',
                style: text.bodyMedium?.copyWith(
                  color: MovrColors.textMuted,
                  height: 1.4,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Image.asset(
                    'assets/images/hero_truck.png',
                    fit: BoxFit.contain,
                    semanticLabel: 'Moving truck loaded with a box and a sofa',
                  ),
                ),
              ),
              _RoleCard(
                icon: Icons.weekend,
                title: 'I need a move',
                subtitle: 'Book a truck in under 60 minutes',
                dark: true,
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const RequestScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _RoleCard(
                icon: Icons.local_shipping,
                title: 'Drive with movr',
                subtitle: 'Earn \$40–\$90/hour with your truck or van',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DriverSignupScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.dark = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : MovrColors.black;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? null : MovrColors.surface,
        gradient: dark ? kCharcoalGradient : null,
        borderRadius: kBorderRadius,
        boxShadow: kFloatingShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: kBorderRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: MovrColors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: kHeadingFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: dark ? Colors.white70 : MovrColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
