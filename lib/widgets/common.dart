import 'package:flutter/material.dart';

import '../theme.dart';

class MovrLogo extends StatelessWidget {
  const MovrLogo({super.key, this.height = 30});
  final double height;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/movr_logo.png',
    height: height,
    semanticLabel: 'movr',
  );
}

/// White rounded card used throughout.
class MovrCard extends StatelessWidget {
  const MovrCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.shadow = false,
  });
  final Widget child;
  final EdgeInsets padding;
  final bool shadow;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: MovrColors.surface,
      borderRadius: kBorderRadius,
      boxShadow: shadow ? kFloatingShadow : null,
    ),
    child: child,
  );
}

/// Pickup → drop-off summary used on the quote and plan sheets.
class RouteSummary extends StatelessWidget {
  const RouteSummary({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.trailing,
  });
  final String pickup;
  final String dropoff;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Column(
          children: [
            const CircleAvatar(radius: 5, backgroundColor: MovrColors.black),
            Container(width: 2, height: 22, color: MovrColors.line),
            const Icon(Icons.location_on, size: 14, color: MovrColors.orange),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pickup,
                style: text.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Text(
                dropoff,
                style: text.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

void showDemoNote(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
