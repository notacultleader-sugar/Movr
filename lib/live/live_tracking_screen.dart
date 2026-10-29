import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../models/move.dart';
import '../screens/completion_screen.dart';
import '../screens/request_screen.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/movr_map.dart';
import 'live_backend.dart';
import 'live_session.dart';
import 'live_widgets.dart';

/// Customer side of a real booking: waits for the driver to accept, then
/// shows the driver's live position and each step as the driver taps it.
class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key, required this.jobId});
  final String jobId;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  late final Stream<LiveJob?> _job = LiveBackend.instance.watchJob(
    widget.jobId,
  );
  bool _finished = false;

  void _onDelivered(LiveJob job) {
    if (_finished) return;
    _finished = true;
    LiveSession.setActiveJob(null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CompletionScreen(order: job.toOrder()),
        ),
      );
    });
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    if (ok == true) await LiveBackend.instance.cancelJob(widget.jobId);
  }

  void _backToMap() {
    LiveSession.setActiveJob(null);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RequestScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LiveJob?>(
      stream: _job,
      builder: (context, snap) {
        final job = snap.data;
        if (snap.hasError) {
          return _Message(
            icon: Icons.wifi_off,
            title: 'Can\'t load your move',
            body:
                'Check your connection. This page updates by itself once '
                'it\'s back.',
            action: 'Back to the map',
            onAction: _backToMap,
          );
        }
        if (job == null) {
          return snap.connectionState == ConnectionState.waiting
              ? const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: MovrColors.orange),
                  ),
                )
              : _Message(
                  icon: Icons.search_off,
                  title: 'This move wasn\'t found',
                  body: 'It may have been removed.',
                  action: 'Back to the map',
                  onAction: _backToMap,
                );
        }
        if (job.status == JobStatus.delivered) _onDelivered(job);
        if (job.status == JobStatus.cancelled) {
          return _Message(
            icon: Icons.cancel_outlined,
            title: 'Request cancelled',
            body: 'Nothing was charged.',
            action: 'Back to the map',
            onAction: _backToMap,
          );
        }
        return _Tracking(job: job, onCancel: _cancel);
      },
    );
  }
}

class _Tracking extends StatelessWidget {
  const _Tracking({required this.job, required this.onCancel});
  final LiveJob job;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final pos = job.driverPos;
    final eta = pos == null
        ? null
        : etaMinutes(
            pos,
            job.status == JobStatus.loaded ? job.dropoff.pos : job.pickup.pos,
          );
    final headline = switch (job.status) {
      JobStatus.requested => 'Finding you a driver…',
      JobStatus.accepted =>
        eta == null
            ? '${job.driver?.name ?? 'Your driver'} is on the way'
            : '${job.driver?.name ?? 'Your driver'} is about $eta min away',
      JobStatus.atPickup => 'Loading at ${job.pickup.name}',
      JobStatus.loaded =>
        eta == null
            ? 'On the way to ${job.dropoff.name}'
            : 'About $eta min to ${job.dropoff.name}',
      _ => job.status.label,
    };
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: RouteBuilder(
              legs: [(job.pickup.pos, job.dropoff.pos)],
              builder: (context, routes, _) => MovrMap(
                fit: [job.pickup.pos, job.dropoff.pos, ?pos],
                padding: EdgeInsets.only(
                  top: 90,
                  bottom: height * 0.45,
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
                      if (pos != null)
                        mapMarker(
                          pos,
                          TruckIcon(
                            highlighted: true,
                            icon: job.quote.vehicle.laborOnly
                                ? Icons.directions_car
                                : Icons.local_shipping,
                          ),
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: kCharcoalGradient,
                  borderRadius: kBorderRadius,
                  boxShadow: kFloatingShadow,
                ),
                child: Row(
                  children: [
                    if (job.status == JobStatus.requested)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: MovrColors.orange,
                        ),
                      )
                    else
                      const Icon(
                        Icons.shield_outlined,
                        color: MovrColors.orange,
                        size: 20,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        headline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.25,
            maxChildSize: 0.85,
            builder: (context, controller) => Container(
              decoration: const BoxDecoration(
                color: MovrColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: MovrColors.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (job.driver != null) ...[
                    _DriverRow(driver: job.driver!),
                    const SizedBox(height: 12),
                    CallButton(
                      phone: job.driver!.phone,
                      label: 'Call ${job.driver!.name}',
                    ),
                    const SizedBox(height: 20),
                  ],
                  StatusTimeline(job: job, etaToPickup: eta),
                  const SizedBox(height: 16),
                  MovrCard(
                    child: RouteSummary(
                      pickup: '${job.pickup.name}, ${job.pickup.address}',
                      dropoff: '${job.dropoff.name}, ${job.dropoff.address}',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: MovrColors.background,
                      borderRadius: kBorderRadius,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_outlined, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('Pay the driver directly')),
                        Text(
                          money(job.quote.total),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  if (job.status == JobStatus.requested) ...[
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: onCancel,
                      child: const Text('Cancel request'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverRow extends StatelessWidget {
  const _DriverRow({required this.driver});
  final DriverProfile driver;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: MovrColors.orange,
          child: Text(
            driver.name.isEmpty ? '?' : driver.name[0],
            style: const TextStyle(
              color: Colors.white,
              fontFamily: kHeadingFont,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(driver.name, style: text.titleLarge),
              if (driver.vehicle.isNotEmpty)
                Text(driver.vehicle, style: text.bodyMedium),
            ],
          ),
        ),
        if (driver.plate.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: MovrColors.black, width: 1.5),
            ),
            child: Text(
              driver.plate,
              style: const TextStyle(
                fontFamily: kHeadingFont,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: MovrColors.orange),
              const SizedBox(height: 16),
              Text(
                title,
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(onPressed: onAction, child: Text(action)),
            ],
          ),
        ),
      ),
    );
  }
}
