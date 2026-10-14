import 'package:flutter/material.dart';

import '../../data/driver_data.dart';
import '../../models/move.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Shown to the driver after a move: what they earned and how it adds up.
class JobCompleteScreen extends StatefulWidget {
  const JobCompleteScreen({super.key, required this.job});
  final JobRequest job;

  @override
  State<JobCompleteScreen> createState() => _JobCompleteScreenState();
}

class _JobCompleteScreenState extends State<JobCompleteScreen> {
  // The customer's tip arrives with their review; the demo uses $10.
  static const _demoTip = 10.0;
  late final DriverPayout _payout = DriverPayout(
    widget.job.quote,
    tip: _demoTip,
  );

  @override
  void initState() {
    super.initState();
    // After the first frame, so listeners don't rebuild mid-build.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => driverSession.completeTrip(widget.job, _payout),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget line(
      String label,
      String value, {
      Color? color,
      bool bold = false,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? MovrColors.black,
              fontSize: bold ? 18 : 14,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          children: [
            const Center(
              child: Icon(
                Icons.check_circle,
                color: MovrColors.orange,
                size: 80,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Move complete',
              textAlign: TextAlign.center,
              style: text.headlineLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'You earned',
              textAlign: TextAlign.center,
              style: text.bodySmall,
            ),
            Text(
              money(_payout.total),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: kHeadingFont,
                fontWeight: FontWeight.w800,
                fontSize: 44,
                color: MovrColors.orange,
              ),
            ),
            const SizedBox(height: 20),
            MovrCard(
              child: Column(
                children: [
                  line('Customer fare', money(_payout.fare)),
                  line(
                    'movr fee (${(DriverPayout.commissionRate * 100).round()}%)',
                    '−${money(_payout.commission)}',
                    color: MovrColors.textMuted,
                  ),
                  line(
                    'Tip from ${widget.job.customer} (100% yours)',
                    '+${money(_payout.tip)}',
                    color: MovrColors.success,
                  ),
                  const Divider(height: 20, color: MovrColors.line),
                  line('Your earnings', money(_payout.total), bold: true),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'The \$${Quote.safetyFee.toStringAsFixed(0)} safety fee the customer paid covers insurance and checks; it isn\'t part of the fare.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 12),
            MovrCard(
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: MovrColors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.job.customer} rated you 5 stars: "Careful" and "On-Time"',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(backgroundColor: MovrColors.black),
              child: const Text('Back to the map'),
            ),
          ],
        ),
      ),
    );
  }
}
