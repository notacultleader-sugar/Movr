import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/driver_data.dart';
import '../../models/move.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Weekly earnings, today's trips and daily cash-out.
class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: ListenableBuilder(
        listenable: driverSession,
        builder: (context, _) {
          final s = driverSession;
          final week = s.week;
          final peak = math.max(week.reduce(math.max), 1.0);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              MovrCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This week', style: text.bodySmall),
                    Text(
                      money(s.weekTotal),
                      style: const TextStyle(
                        fontFamily: kHeadingFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 130,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < week.length; i++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (week[i] > 0)
                                      Text(
                                        '\$${week[i].round()}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      height: math.max(4, 84 * week[i] / peak),
                                      decoration: BoxDecoration(
                                        color: i == DriverSession.todayIndex
                                            ? MovrColors.orange
                                            : MovrColors.black,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _days[i],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight:
                                            i == DriverSession.todayIndex
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                        color: i == DriverSession.todayIndex
                                            ? MovrColors.black
                                            : MovrColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              MovrCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ready to cash out', style: text.bodySmall),
                          Text(
                            money(s.available),
                            style: const TextStyle(
                              fontFamily: kHeadingFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              color: MovrColors.orange,
                            ),
                          ),
                          Text('To bank ****1234', style: text.bodySmall),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: FilledButton(
                        onPressed: s.available > 0
                            ? () {
                                final amount = s.available;
                                s.cashOut();
                                showDemoNote(
                                  context,
                                  '${money(amount)} sent to bank ****1234 (demo)',
                                );
                              }
                            : null,
                        child: const Text('Cash out'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Today\'s moves', style: text.titleLarge),
              const SizedBox(height: 8),
              if (s.todayTrips.isEmpty)
                Text(
                  'No moves yet today. Go online to get requests.',
                  style: text.bodySmall,
                ),
              for (final t in s.todayTrips)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MovrCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(t.job.items.first.icon),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${t.job.pickup.name} › ${t.job.dropoff.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleMedium,
                              ),
                              Text(
                                '${t.job.quote.miles.toStringAsFixed(1)} mi · fare ${money(t.payout.fare)} · '
                                'tip ${money(t.payout.tip)}',
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          money(t.payout.total),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'You keep ${(100 * (1 - DriverPayout.commissionRate)).round()}% of every fare and 100% of tips.',
                style: text.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
