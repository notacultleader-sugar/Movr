import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/move.dart';
import '../services/location.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/movr_map.dart';
import 'live_backend.dart';
import 'live_widgets.dart';

/// The driver's side of a real job. Shares the phone's location with the
/// customer while the job is active, and moves it along stop by stop.
class LiveDriverJobScreen extends StatefulWidget {
  const LiveDriverJobScreen({super.key, required this.jobId, required this.me});
  final String jobId;
  final DriverProfile me;

  @override
  State<LiveDriverJobScreen> createState() => _LiveDriverJobScreenState();
}

class _LiveDriverJobScreenState extends State<LiveDriverJobScreen> {
  late final Stream<LiveJob?> _job = LiveBackend.instance.watchJob(
    widget.jobId,
  );
  StreamSubscription<LatLng>? _gps;
  LatLng? _here;
  DateTime _lastSent = DateTime(2000);
  bool _locationOff = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _gps = DeviceLocation.watch().listen(
      _onPosition,
      onError: (_) {
        if (mounted) setState(() => _locationOff = true);
      },
    );
  }

  @override
  void dispose() {
    _gps?.cancel();
    super.dispose();
  }

  void _onPosition(LatLng p) {
    if (!mounted) return;
    setState(() {
      _here = p;
      _locationOff = false;
    });
    // At most one update every 5 seconds keeps the free tier comfortable.
    final now = DateTime.now();
    if (now.difference(_lastSent) < const Duration(seconds: 5)) return;
    _lastSent = now;
    LiveBackend.instance.updateDriverPos(widget.jobId, p).catchError((_) {});
  }

  Future<void> _advance(LiveJob job) async {
    final next = switch (job.status) {
      JobStatus.accepted => JobStatus.atPickup,
      JobStatus.atPickup => JobStatus.loaded,
      JobStatus.loaded => JobStatus.delivered,
      _ => null,
    };
    if (next == null) return;
    setState(() => _busy = true);
    try {
      await LiveBackend.instance.setStatus(job.id, next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t update. Check your signal.')),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LiveJob?>(
      stream: _job,
      builder: (context, snap) {
        final job = snap.data;
        if (job == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: snap.connectionState == ConnectionState.waiting
                  ? const CircularProgressIndicator(color: MovrColors.orange)
                  : const Text('This job is no longer available.'),
            ),
          );
        }
        if (job.status == JobStatus.delivered) {
          _gps?.cancel();
          return _Done(job: job);
        }
        if (job.status == JobStatus.cancelled) {
          _gps?.cancel();
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('The customer cancelled this job.')),
          );
        }
        return _Active(
          job: job,
          here: _here,
          locationOff: _locationOff,
          busy: _busy,
          onAdvance: () => _advance(job),
        );
      },
    );
  }
}

class _Active extends StatelessWidget {
  const _Active({
    required this.job,
    required this.here,
    required this.locationOff,
    required this.busy,
    required this.onAdvance,
  });
  final LiveJob job;
  final LatLng? here;
  final bool locationOff;
  final bool busy;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final height = MediaQuery.sizeOf(context).height;
    final toPickup = job.status == JobStatus.accepted;
    final stop = toPickup || job.status == JobStatus.atPickup
        ? job.pickup
        : job.dropoff;
    final (title, button) = switch (job.status) {
      JobStatus.accepted => ('Head to pickup', 'I\'ve arrived at pickup'),
      JobStatus.atPickup => ('Load up', 'Loaded, heading to drop-off'),
      _ => ('Head to drop-off', 'Delivered'),
    };
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: RouteBuilder(
              legs: [(job.pickup.pos, job.dropoff.pos)],
              builder: (context, routes, _) => MovrMap(
                key: ValueKey(here != null),
                fit: [job.pickup.pos, job.dropoff.pos, ?here],
                padding: EdgeInsets.only(
                  top: 90,
                  bottom: height * 0.48,
                  left: 24,
                  right: 24,
                ),
                layers: [
                  routeLayer(routes.first),
                  MarkerLayer(
                    markers: [
                      mapMarker(job.pickup.pos, const PickupPin(), size: 24),
                      mapMarker(
                        job.dropoff.pos,
                        const DropoffPin(),
                        size: 40,
                        anchorBottom: true,
                      ),
                      if (here != null)
                        mapMarker(
                          here!,
                          const TruckIcon(highlighted: true),
                          size: 36,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PilotBadge(
                text: locationOff
                    ? 'Location off: the customer can\'t see you'
                    : 'Sharing your location with ${job.contactName}',
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: BoxConstraints(maxHeight: height * 0.55),
              decoration: const BoxDecoration(
                color: MovrColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
              ),
              child: SafeArea(
                top: false,
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  children: [
                    Text(title, style: text.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      '${stop.name}, ${stop.address}',
                      style: text.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => openDirections(stop.pos),
                            icon: const Icon(Icons.navigation_outlined),
                            label: const Text('Directions'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CallButton(
                            phone: job.contactPhone,
                            label: 'Call',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    MovrCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${job.contactName} · ${job.contactPhone}',
                            style: text.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.quote.vehicle.laborOnly
                                ? 'Muscle · ${job.quote.helpers} helper(s) · '
                                      '${job.quote.hours} hr'
                                : '${job.quote.vehicle.name} · '
                                      '${job.quote.items.isEmpty ? 'items not listed' : job.quote.items.map((i) => i.name).join(', ')}',
                          ),
                          if (job.notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Notes: ${job.notes}'),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            'Collect ${money(job.quote.total)} at the end',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: MovrColors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: busy ? null : onAdvance,
                      child: Text(button),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.job});
  final LiveJob job;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final payout = DriverPayout(job.quote);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.check_circle, color: MovrColors.orange, size: 72),
            const SizedBox(height: 12),
            Text(
              'Move complete',
              style: text.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            MovrCard(
              child: Column(
                children: [
                  _row('Collected from customer', money(job.quote.total)),
                  _row('Safety fee (movr)', '-${money(Quote.safetyFee)}'),
                  _row('movr commission (25%)', '-${money(payout.commission)}'),
                  const Divider(),
                  _row('You keep', money(payout.total), bold: true),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilot: settle movr\'s share with the team directly. Tips are '
              'all yours.',
              style: text.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to requests'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
