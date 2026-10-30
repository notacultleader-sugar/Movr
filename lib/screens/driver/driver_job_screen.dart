import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/driver_data.dart';
import '../../models/move.dart';
import '../../theme.dart';
import '../../services/routing.dart';
import '../../widgets/movr_map.dart';
import '../../widgets/common.dart';
import 'job_complete_screen.dart';

enum _Stage { toPickup, loading, toDropoff, unloading }

/// The driver's side of an active move: drive to pickup, load, drive to
/// drop-off, unload, complete. Each driving leg is simulated (about 6
/// seconds) and the driver taps through the stops.
class DriverJobScreen extends StatefulWidget {
  const DriverJobScreen({super.key, required this.job});
  final JobRequest job;

  @override
  State<DriverJobScreen> createState() => _DriverJobScreenState();
}

class _DriverJobScreenState extends State<DriverJobScreen>
    with SingleTickerProviderStateMixin {
  static const _start = driverHomeSpot;

  late final AnimationController _drive =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..addListener(() => setState(() {}))
        ..forward();

  late List<LatLng> _approach = [_start, widget.job.pickup.pos];
  late List<LatLng> _delivery = [widget.job.pickup.pos, widget.job.dropoff.pos];

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final job = widget.job;
    final routes = await Future.wait([
      Routing.route(_start, job.pickup.pos),
      Routing.route(job.pickup.pos, job.dropoff.pos),
    ]);
    if (!mounted) return;
    setState(() {
      _approach = routes[0];
      _delivery = routes[1];
    });
  }

  _Stage _stage = _Stage.toPickup;
  bool _loadedConfirmed = false;
  bool _photoTaken = false;

  bool get _driving => _stage == _Stage.toPickup || _stage == _Stage.toDropoff;
  bool get _arrived => _drive.isCompleted;

  LatLng get _truckPos => switch (_stage) {
    _Stage.toPickup => pointAlong(_approach, _drive.value),
    _Stage.loading => widget.job.pickup.pos,
    _Stage.toDropoff => pointAlong(_delivery, _drive.value),
    _Stage.unloading => widget.job.dropoff.pos,
  };

  @override
  void dispose() {
    _drive.dispose();
    super.dispose();
  }

  void _advance() {
    switch (_stage) {
      case _Stage.toPickup:
        setState(() => _stage = _Stage.loading);
      case _Stage.loading:
        setState(() {
          _stage = _Stage.toDropoff;
          _drive.forward(from: 0);
        });
      case _Stage.toDropoff:
        setState(() => _stage = _Stage.unloading);
      case _Stage.unloading:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => JobCompleteScreen(job: widget.job)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final height = MediaQuery.sizeOf(context).height;
    final pos = _truckPos;
    final path = _stage.index <= _Stage.loading.index ? _approach : _delivery;
    final ahead = _driving
        ? pointAlong(path, (_drive.value + 0.01).clamp(0.0, 1.0))
        : pos;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MovrMap(
              fit: [_start, job.pickup.pos, job.dropoff.pos],
              padding: EdgeInsets.only(
                top: 100,
                bottom: height * 0.45,
                left: 24,
                right: 24,
              ),
              layers: [
                routeLayer(_delivery),
                if (_stage.index <= _Stage.loading.index)
                  routeLayer(_approach, color: MovrColors.orange, dashed: true),
                MarkerLayer(
                  markers: [
                    mapMarker(job.pickup.pos, const PickupPin(), size: 24),
                    mapMarker(
                      job.dropoff.pos,
                      const DropoffPin(),
                      size: 40,
                      anchorBottom: true,
                    ),
                    mapMarker(
                      pos,
                      TruckIcon(
                        highlighted: true,
                        facingLeft: ahead.longitude < pos.longitude,
                      ),
                      size: 36,
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: MovrColors.black,
                    borderRadius: kBorderRadius,
                    boxShadow: kFloatingShadow,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _driving
                            ? Icons.navigation
                            : Icons.inventory_2_outlined,
                        color: MovrColors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _headline,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              _subline,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: MovrColors.surface,
              elevation: 8,
              shadowColor: Colors.black26,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: MovrColors.orangeTint,
                            child: Text(
                              job.customer[0],
                              style: const TextStyle(
                                color: MovrColors.orange,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${job.customer} · rated ${job.customerRating}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                Text(
                                  job.items
                                      .map((i) => '${i.name} (${i.size.label})')
                                      .join(', '),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Call customer',
                            onPressed: () => showDemoNote(
                              context,
                              'Calling ${job.customer} on a masked number (demo)',
                            ),
                            icon: const Icon(Icons.call),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Message customer',
                            onPressed: () => showDemoNote(
                              context,
                              'Message sent: "On my way!" (demo)',
                            ),
                            icon: const Icon(Icons.chat_bubble_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _StopRow(
                        icon: Icons.circle,
                        iconSize: 12,
                        color: MovrColors.black,
                        label: 'Pickup',
                        place: job.pickup,
                        done: _stage.index > _Stage.loading.index,
                        current: _stage.index <= _Stage.loading.index,
                      ),
                      const SizedBox(height: 8),
                      _StopRow(
                        icon: Icons.location_on,
                        iconSize: 18,
                        color: MovrColors.orange,
                        label: 'Drop-off',
                        place: job.dropoff,
                        done: false,
                        current: _stage.index >= _Stage.toDropoff.index,
                      ),
                      if (_stage == _Stage.loading) ...[
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: _photoTaken,
                          onChanged: (v) =>
                              setState(() => _photoTaken = v ?? false),
                          title: const Text('Take a photo of the load'),
                          subtitle: const Text(
                            'Protects you and the customer if anything is damaged',
                          ),
                        ),
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: _loadedConfirmed,
                          onChanged: (v) =>
                              setState(() => _loadedConfirmed = v ?? false),
                          title: const Text('Items loaded and strapped down'),
                        ),
                      ],
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _canAdvance ? _advance : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _stage == _Stage.unloading
                              ? MovrColors.orange
                              : MovrColors.black,
                        ),
                        child: Text(_buttonLabel),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canAdvance => switch (_stage) {
    _Stage.toPickup || _Stage.toDropoff => _arrived,
    _Stage.loading => _loadedConfirmed && _photoTaken,
    _Stage.unloading => true,
  };

  String get _buttonLabel => switch (_stage) {
    _Stage.toPickup =>
      _arrived ? 'I\'ve arrived at pickup' : 'Driving to pickup…',
    _Stage.loading => 'Start trip',
    _Stage.toDropoff =>
      _arrived ? 'I\'ve arrived at drop-off' : 'Driving to drop-off…',
    _Stage.unloading => 'Complete move',
  };

  String get _headline => switch (_stage) {
    _Stage.toPickup =>
      _arrived ? 'You\'ve arrived' : 'Head to ${widget.job.pickup.name}',
    _Stage.loading => 'Load the items',
    _Stage.toDropoff =>
      _arrived ? 'You\'ve arrived' : 'Head to ${widget.job.dropoff.name}',
    _Stage.unloading => 'Unload and confirm with ${widget.job.customer}',
  };

  String get _subline => switch (_stage) {
    _Stage.toPickup =>
      '${widget.job.pickup.address} · ${(4 * (1 - _drive.value)).ceil()} min',
    _Stage.loading => 'Customer notified you\'re here',
    _Stage.toDropoff =>
      '${widget.job.dropoff.address} · ${(widget.job.quote.miles * (1 - _drive.value)).toStringAsFixed(1)} mi',
    _Stage.unloading => widget.job.dropoff.address,
  };
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.icon,
    required this.iconSize,
    required this.color,
    required this.label,
    required this.place,
    required this.done,
    required this.current,
  });

  final IconData icon;
  final double iconSize;
  final Color color;
  final String label;
  final Place place;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Center(
            child: Icon(
              done ? Icons.check_circle : icon,
              size: done ? 20 : iconSize,
              color: done ? MovrColors.success : color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: MovrColors.textMuted,
                ),
              ),
              Text(
                '${place.name}, ${place.address}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                  color: current || done
                      ? MovrColors.black
                      : MovrColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
