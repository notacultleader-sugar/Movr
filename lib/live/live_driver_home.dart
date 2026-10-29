import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/mock_data.dart';
import '../models/move.dart';
import '../screens/welcome_screen.dart';
import '../services/location.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/movr_map.dart';
import 'live_backend.dart';
import 'live_driver_job.dart';
import 'live_widgets.dart';

/// Pilot driver home: go online, see real requests as they come in, accept.
class LiveDriverHome extends StatefulWidget {
  const LiveDriverHome({super.key, required this.me});
  final DriverProfile me;

  @override
  State<LiveDriverHome> createState() => _LiveDriverHomeState();
}

class _LiveDriverHomeState extends State<LiveDriverHome> {
  bool _online = false;
  LatLng? _here;
  bool _locationOff = false;
  StreamSubscription<LatLng>? _gps;
  StreamSubscription<List<LiveJob>>? _jobsSub;
  List<LiveJob> _open = const [];
  final Set<String> _skipped = {};
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _resumeActiveJob();
  }

  @override
  void dispose() {
    _gps?.cancel();
    _jobsSub?.cancel();
    super.dispose();
  }

  Future<void> _resumeActiveJob() async {
    try {
      final job = await LiveBackend.instance.activeJobFor(widget.me.uid);
      if (job != null && mounted) _openJob(job.id);
    } catch (_) {}
  }

  void _setOnline(bool online) {
    setState(() {
      _online = online;
      _open = const [];
    });
    _gps?.cancel();
    _jobsSub?.cancel();
    if (!online) return;
    _gps = DeviceLocation.watch().listen(
      (p) => setState(() {
        _here = p;
        _locationOff = false;
      }),
      onError: (_) => setState(() => _locationOff = true),
    );
    _jobsSub = LiveBackend.instance.watchOpenJobs().listen(
      (jobs) => setState(() => _open = jobs),
      onError: (_) {},
    );
  }

  LiveJob? get _offer {
    for (final j in _open) {
      if (!_skipped.contains(j.id)) return j;
    }
    return null;
  }

  Future<void> _accept(LiveJob job) async {
    setState(() => _accepting = true);
    var ok = false;
    try {
      ok = await LiveBackend.instance.acceptJob(job.id, widget.me, _here);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _accepting = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That request is no longer available.')),
      );
      return;
    }
    _openJob(job.id);
  }

  Future<void> _openJob(String id) async {
    _gps?.cancel();
    _jobsSub?.cancel();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveDriverJobScreen(jobId: id, me: widget.me),
      ),
    );
    if (mounted) _setOnline(_online);
  }

  Future<void> _signOut() async {
    await LiveBackend.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = _online ? _offer : null;
    final here = _here;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MovrMap(
              key: ValueKey('${offer?.id}-${here != null}'),
              fit: [
                if (offer != null) ...[offer.pickup.pos, offer.dropoff.pos],
                if (offer == null) ...[
                  here ?? duncanCentre,
                  const LatLng(48.7900, -123.7230),
                  const LatLng(48.7650, -123.6950),
                ],
                ?here,
              ],
              padding: EdgeInsets.only(
                top: 90,
                bottom: offer != null ? 320 : 220,
              ),
              layers: [
                if (offer != null)
                  RouteBuilder(
                    legs: [(offer.pickup.pos, offer.dropoff.pos)],
                    builder: (context, routes, _) => routeLayer(routes.first),
                  ),
                MarkerLayer(
                  markers: [
                    if (offer != null) ...[
                      mapMarker(offer.pickup.pos, const PickupPin(), size: 24),
                      mapMarker(
                        offer.dropoff.pos,
                        const DropoffPin(),
                        size: 40,
                        anchorBottom: true,
                      ),
                    ],
                    if (here != null)
                      mapMarker(
                        here,
                        TruckIcon(highlighted: _online),
                        size: 38,
                      ),
                  ],
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
                    PilotBadge(text: '${widget.me.name} · pilot driver'),
                    const Spacer(),
                    Material(
                      color: MovrColors.surface,
                      shape: const CircleBorder(),
                      elevation: 4,
                      shadowColor: Colors.black26,
                      child: IconButton(
                        tooltip: 'Sign out',
                        icon: const Icon(Icons.logout),
                        onPressed: _signOut,
                      ),
                    ),
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
              child: offer != null
                  ? _OfferCard(
                      key: ValueKey(offer.id),
                      job: offer,
                      from: here,
                      busy: _accepting,
                      onAccept: () => _accept(offer),
                      onSkip: () => setState(() => _skipped.add(offer.id)),
                    )
                  : _StatusCard(
                      online: _online,
                      locationOff: _locationOff,
                      onToggle: _setOnline,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.online,
    required this.locationOff,
    required this.onToggle,
  });
  final bool online;
  final bool locationOff;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return MovrCard(
      shadow: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      style: text.titleLarge,
                    ),
                    Text(
                      online
                          ? 'Waiting for requests. Keep this screen open.'
                          : 'Go online to get move requests.',
                      style: text.bodySmall,
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
          if (online && locationOff) ...[
            const SizedBox(height: 10),
            Text(
              'Location is off. Allow location for this site so customers '
              'can see where you are.',
              style: text.bodySmall?.copyWith(color: Colors.red),
            ),
          ],
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
    required this.from,
    required this.busy,
    required this.onAccept,
    required this.onSkip,
  });

  final LiveJob job;
  final LatLng? from;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final quote = job.quote;
    final payout = DriverPayout(quote);
    final away = from == null ? null : etaMinutes(from!, job.pickup.pos);
    return MovrCard(
      shadow: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New ${quote.vehicle.name} request', style: text.titleLarge),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(quote.total),
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
                child: Text(
                  'collect from customer · you keep ${money(payout.total)}',
                  style: text.bodySmall,
                ),
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
            [
              if (away != null) '$away min to pickup',
              '${quote.miles.toStringAsFixed(1)} mi trip',
              if (quote.vehicle.laborOnly)
                '${quote.helpers} helper(s) · ${quote.hours} hr'
              else if (quote.items.isNotEmpty)
                quote.items.map((i) => i.name).join(', '),
              job.contactName,
            ].join(' · '),
            style: text.bodySmall,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onSkip,
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: busy ? null : onAccept,
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
