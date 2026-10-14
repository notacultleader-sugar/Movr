import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/driver_data.dart';
import '../../models/move.dart';
import '../../theme.dart';
import '../../widgets/city_map.dart';
import '../../widgets/common.dart';
import '../request_screen.dart';
import 'driver_job_screen.dart';
import 'earnings_screen.dart';

/// Driver home: go online, receive job requests, accept or decline.
///
/// Prototype: requests come from a mock pool a few seconds after going
/// online. A real build would receive dispatches from the matching server.
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  static const _position = Offset(390, 530);
  static const _offerSeconds = 15;

  bool _online = false;
  JobRequest? _offer;
  int _secondsLeft = _offerSeconds;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setOnline(bool online) {
    _timer?.cancel();
    setState(() {
      _online = online;
      _offer = null;
    });
    if (online) _waitForOffer();
  }

  void _waitForOffer() {
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted || !_online) return;
      setState(() {
        _offer = driverSession.nextJob();
        _secondsLeft = _offerSeconds;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() => _secondsLeft--);
        if (_secondsLeft <= 0) _decline();
      });
    });
  }

  void _decline() {
    _timer?.cancel();
    setState(() => _offer = null);
    _waitForOffer();
  }

  Future<void> _accept() async {
    final job = _offer!;
    _timer?.cancel();
    setState(() => _offer = null);
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => DriverJobScreen(job: job)));
    if (mounted && _online) _waitForOffer();
  }

  void _menu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(driverSession.vehicleType.icon),
                title: Text('${driverSession.name} · ${driverSession.rating}'),
                subtitle: Text(
                  '${driverSession.vehicle} · ${driverSession.plate}',
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Earnings & payouts'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheet);
                  _openEarnings();
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.weekend),
                label: const Text('Switch to customer mode'),
                onPressed: () {
                  Navigator.pop(sheet);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const RequestScreen()),
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEarnings() =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const EarningsScreen()));

  @override
  Widget build(BuildContext context) {
    final offer = _offer;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CityMap(
              focus: const Rect.fromLTWH(140, 200, 560, 640),
              overlays: (p) => [
                if (offer != null) ...[
                  Positioned.fill(
                    child: RouteLayer(
                      projection: p,
                      path: roadRoute(_position, offer.pickup.mapPos),
                      color: MovrColors.orange,
                      dashed: true,
                    ),
                  ),
                  Positioned.fill(
                    child: RouteLayer(
                      projection: p,
                      path: roadRoute(
                        offer.pickup.mapPos,
                        offer.dropoff.mapPos,
                      ),
                    ),
                  ),
                  MapMarker(
                    projection: p,
                    at: offer.pickup.mapPos,
                    size: 24,
                    child: const PickupPin(),
                  ),
                  MapMarker(
                    projection: p,
                    at: offer.dropoff.mapPos,
                    size: 40,
                    anchorBottom: true,
                    child: const DropoffPin(),
                  ),
                ],
                MapMarker(
                  projection: p,
                  at: _position,
                  size: 38,
                  child: TruckIcon(highlighted: _online),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Material(
                      color: MovrColors.surface,
                      shape: const CircleBorder(),
                      elevation: 4,
                      shadowColor: Colors.black26,
                      child: IconButton(
                        tooltip: 'Menu',
                        icon: const Icon(Icons.menu),
                        onPressed: _menu,
                      ),
                    ),
                    const Spacer(),
                    ListenableBuilder(
                      listenable: driverSession,
                      builder: (context, _) => GestureDetector(
                        onTap: _openEarnings,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: MovrColors.black,
                            borderRadius: kBorderRadius,
                            boxShadow: kFloatingShadow,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Today',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                money(driverSession.todayEarnings),
                                style: const TextStyle(
                                  color: MovrColors.orange,
                                  fontFamily: kHeadingFont,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: offer != null
                    ? _OfferCard(
                        key: ValueKey(offer),
                        job: offer,
                        secondsLeft: _secondsLeft,
                        total: _offerSeconds,
                        onAccept: _accept,
                        onDecline: _decline,
                      )
                    : _StatusCard(
                        key: ValueKey(_online),
                        online: _online,
                        onToggle: _setOnline,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({super.key, required this.online, required this.onToggle});
  final bool online;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return MovrCard(
      shadow: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 6,
                backgroundColor: online
                    ? MovrColors.success
                    : MovrColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      online ? 'You\'re online' : 'You\'re offline',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      online
                          ? 'Looking for moves near you…'
                          : 'Go online to start getting move requests.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (online)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => onToggle(!online),
            style: FilledButton.styleFrom(
              backgroundColor: online ? MovrColors.black : MovrColors.orange,
            ),
            child: Text(online ? 'Go offline' : 'Go online'),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    super.key,
    required this.job,
    required this.secondsLeft,
    required this.total,
    required this.onAccept,
    required this.onDecline,
  });

  final JobRequest job;
  final int secondsLeft;
  final int total;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final quote = job.quote;
    return MovrCard(
      shadow: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('New ${job.vehicle.name} request', style: text.titleLarge),
              const Spacer(),
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: secondsLeft / total,
                      strokeWidth: 4,
                      color: MovrColors.orange,
                      backgroundColor: MovrColors.line,
                    ),
                    Text(
                      '$secondsLeft',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(job.payout.total),
                style: const TextStyle(
                  fontFamily: kHeadingFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 34,
                  color: MovrColors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('est. earnings + tips', style: text.bodySmall),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${job.pickup.name} › ${job.dropoff.name}',
            style: text.titleMedium,
          ),
          const SizedBox(height: 2),
          Text(
            '${quote.miles.toStringAsFixed(1)} mi trip · '
            '${job.items.map((i) => i.name).join(', ')} · ${job.customer}, rated ${job.customerRating}',
            style: text.bodySmall,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
