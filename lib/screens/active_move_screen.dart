import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/move.dart';
import '../theme.dart';
import '../services/routing.dart';
import '../widgets/movr_map.dart';
import 'completion_screen.dart';

enum MovePhase { accepted, enRoute, loading, inTransit, done }

/// Stage 3: The Active Move. Live tracking for peace of mind: the driver's
/// truck moves on the map while the timeline advances.
///
/// Prototype: the trip is simulated and fast-forwarded (about 25 seconds
/// end to end). A real build would follow the driver's GPS updates.
class ActiveMoveScreen extends StatefulWidget {
  const ActiveMoveScreen({super.key, required this.order});
  final MoveOrder order;

  @override
  State<ActiveMoveScreen> createState() => _ActiveMoveScreenState();
}

class _ActiveMoveScreenState extends State<ActiveMoveScreen>
    with SingleTickerProviderStateMixin {
  // Seconds spent in each phase of the simulated trip.
  static const _accepted = 2.0,
      _enRoute = 8.0,
      _loading = 4.0,
      _inTransit = 9.0,
      _done = 1.5;
  static const _total = _accepted + _enRoute + _loading + _inTransit + _done;

  late final AnimationController _trip =
      AnimationController(
          vsync: this,
          duration: Duration(milliseconds: (_total * 1000).round()),
        )
        ..addListener(() => setState(() {}))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) _finish();
        })
        ..forward();

  // Straight lines until the real road routes arrive (in well under the
  // two-second "accepted" phase on a normal connection).
  late List<LatLng> _approach = [
    widget.order.driverStart,
    widget.order.pickup.pos,
  ];
  late List<LatLng> _delivery = [
    widget.order.pickup.pos,
    widget.order.dropoff.pos,
  ];

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final o = widget.order;
    final routes = await Future.wait([
      Routing.route(o.driverStart, o.pickup.pos),
      Routing.route(o.pickup.pos, o.dropoff.pos),
    ]);
    if (!mounted) return;
    setState(() {
      _approach = routes[0];
      _delivery = routes[1];
    });
  }

  double _sheetExtent = 0.42;

  double get _seconds => _trip.value * _total;

  MovePhase get _phase {
    final s = _seconds;
    if (s < _accepted) return MovePhase.accepted;
    if (s < _accepted + _enRoute) return MovePhase.enRoute;
    if (s < _accepted + _enRoute + _loading) return MovePhase.loading;
    if (s < _total - _done) return MovePhase.inTransit;
    return MovePhase.done;
  }

  /// Fraction (0..1) through the current driving leg.
  double _legProgress(double start, double length) =>
      ((_seconds - start) / length).clamp(0.0, 1.0);

  LatLng get _driverPos => switch (_phase) {
    MovePhase.accepted => widget.order.driverStart,
    MovePhase.enRoute => pointAlong(
      _approach,
      _legProgress(_accepted, _enRoute),
    ),
    MovePhase.loading => widget.order.pickup.pos,
    MovePhase.inTransit => pointAlong(
      _delivery,
      _legProgress(_accepted + _enRoute + _loading, _inTransit),
    ),
    MovePhase.done => widget.order.dropoff.pos,
  };

  int get _minutesAway =>
      (4 * (1 - _legProgress(_accepted, _enRoute))).ceil().clamp(1, 4);

  void _finish() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => CompletionScreen(order: widget.order)),
    );
  }

  @override
  void dispose() {
    _trip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final driverPos = _driverPos;
    final legPath = _phase.index <= MovePhase.enRoute.index
        ? _approach
        : _delivery;
    final ahead = _phase == MovePhase.enRoute
        ? pointAlong(
            _approach,
            (_legProgress(_accepted, _enRoute) + 0.01).clamp(0.0, 1.0),
          )
        : pointAlong(
            _delivery,
            (_legProgress(_accepted + _enRoute + _loading, _inTransit) + 0.01)
                .clamp(0.0, 1.0),
          );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MovrMap(
              fit: [
                widget.order.driverStart,
                widget.order.pickup.pos,
                widget.order.dropoff.pos,
              ],
              padding: EdgeInsets.only(
                top: 90,
                bottom: height * 0.42,
                left: 24,
                right: 24,
              ),
              layers: [
                routeLayer(_delivery),
                if (_phase.index <= MovePhase.enRoute.index)
                  routeLayer(legPath, color: MovrColors.orange, dashed: true),
                MarkerLayer(
                  markers: [
                    mapMarker(
                      widget.order.pickup.pos,
                      const PickupPin(),
                      size: 24,
                    ),
                    mapMarker(
                      widget.order.dropoff.pos,
                      const DropoffPin(),
                      size: 40,
                      anchorBottom: true,
                    ),
                    mapMarker(
                      driverPos,
                      TruckIcon(
                        highlighted: true,
                        icon: widget.order.quote.vehicle.laborOnly
                            ? Icons.directions_car
                            : Icons.local_shipping,
                        facingLeft: ahead.longitude < driverPos.longitude,
                      ),
                      size: 36,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: MovrColors.black,
                  borderRadius: kBorderRadius,
                  boxShadow: kFloatingShadow,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: MovrColors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _headline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Text(
                      'Insured \$15k',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Floating Call / Message buttons ride just above the sheet.
          Positioned(
            right: 16,
            bottom: height * _sheetExtent + 12,
            child: Column(
              children: [
                _FloatingAction(icon: Icons.call, label: 'Call', onTap: _call),
                const SizedBox(height: 10),
                _FloatingAction(
                  icon: Icons.chat_bubble_outline,
                  label: 'Message',
                  onTap: _message,
                ),
              ],
            ),
          ),
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (n) {
              setState(() => _sheetExtent = n.extent);
              return false;
            },
            child: DraggableScrollableSheet(
              initialChildSize: 0.42,
              minChildSize: 0.22,
              maxChildSize: 0.7,
              builder: (context, controller) => _DriverSheet(
                controller: controller,
                order: widget.order,
                phase: _phase,
                minutesAway: _minutesAway,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _headline => switch (_phase) {
    MovePhase.accepted => '${widget.order.driver.name} accepted your move',
    MovePhase.enRoute =>
      '${widget.order.driver.name} is $_minutesAway min away',
    MovePhase.loading => 'Loading at pickup',
    MovePhase.inTransit => 'On the way to ${widget.order.dropoff.name}',
    MovePhase.done => 'Arrived!',
  };

  void _call() {
    final d = widget.order.driver;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
        icon: const Icon(Icons.call, color: MovrColors.orange, size: 36),
        title: Text('Calling ${d.name}…'),
        content: const Text(
          'Your number stays private: calls go through a masked movr line.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              minimumSize: const Size(140, 48),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('End call'),
          ),
        ],
      ),
    );
  }

  void _message() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ChatSheet(driver: widget.order.driver),
    );
  }
}

class _FloatingAction extends StatelessWidget {
  const _FloatingAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: MovrColors.surface,
    borderRadius: kBorderRadius,
    elevation: 6,
    shadowColor: Colors.black26,
    child: InkWell(
      borderRadius: kBorderRadius,
      onTap: onTap,
      child: SizedBox(
        width: 64,
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: MovrColors.orange),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DriverSheet extends StatelessWidget {
  const _DriverSheet({
    required this.controller,
    required this.order,
    required this.phase,
    required this.minutesAway,
  });
  final ScrollController controller;
  final MoveOrder order;
  final MovePhase phase;
  final int minutesAway;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final d = order.driver;
    return Container(
      decoration: BoxDecoration(
        color: MovrColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: kFloatingShadow,
      ),
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
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
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [MovrColors.orange, Color(0xFFFF5F00)],
                  ),
                  border: Border.all(color: MovrColors.black, width: 3),
                ),
                alignment: Alignment.center,
                child: Text(
                  d.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: kHeadingFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('${d.name} · ${d.rating}', style: text.titleLarge),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.star_rounded,
                          color: MovrColors.orange,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(d.vehicle, style: text.bodyMedium),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: MovrColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: MovrColors.black, width: 1.5),
                ),
                child: Text(
                  d.plate,
                  style: const TextStyle(
                    fontFamily: kHeadingFont,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Live status', style: text.titleLarge),
          const SizedBox(height: 8),
          _TimelineStep(
            label: 'Request Accepted',
            state: _stateFor(MovePhase.accepted),
          ),
          _TimelineStep(
            label: phase == MovePhase.enRoute
                ? '${order.quote.vehicle.laborOnly ? 'Helpers' : 'Driver'} en route ($minutesAway min${minutesAway == 1 ? '' : 's'} away)'
                : '${order.quote.vehicle.laborOnly ? 'Helpers' : 'Driver'} en route',
            state: _stateFor(MovePhase.enRoute),
          ),
          _TimelineStep(label: 'Loading', state: _stateFor(MovePhase.loading)),
          _TimelineStep(
            label: 'In Transit',
            state: _stateFor(MovePhase.inTransit),
            last: true,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MovrColors.background,
              borderRadius: kBorderRadius,
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order.quote.vehicle.laborOnly
                        ? 'Muscle · ${order.quote.helpers} helper(s) · ${order.quote.hours} hr'
                        : '${order.quote.vehicle.name} · ${order.quote.items.length} item(s) · ${order.quote.miles} mi',
                  ),
                ),
                Text(
                  money(order.quote.total),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _StepState _stateFor(MovePhase step) {
    // The "accepted" step is complete as soon as the screen opens.
    if (step == MovePhase.accepted) return _StepState.done;
    if (phase.index > step.index) return _StepState.done;
    if (phase == step) return _StepState.active;
    return _StepState.pending;
  }
}

enum _StepState { done, active, pending }

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.state,
    this.last = false,
  });
  final String label;
  final _StepState state;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final Widget dot = switch (state) {
      _StepState.done => const Icon(
        Icons.check_circle,
        color: MovrColors.success,
        size: 22,
      ),
      _StepState.active => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: MovrColors.enRoute.withValues(alpha: 0.2),
        ),
        alignment: Alignment.center,
        child: const CircleAvatar(
          radius: 6,
          backgroundColor: MovrColors.enRoute,
        ),
      ),
      _StepState.pending => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: MovrColors.line, width: 2.5),
        ),
      ),
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              dot,
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    color: state == _StepState.done
                        ? MovrColors.success
                        : MovrColors.line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 1, bottom: last ? 0 : 18),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: state == _StepState.pending
                      ? FontWeight.w500
                      : FontWeight.w700,
                  color: state == _StepState.pending
                      ? MovrColors.textMuted
                      : MovrColors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatSheet extends StatefulWidget {
  const _ChatSheet({required this.driver});
  final Driver driver;

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  late final List<(bool, String)> _messages = [
    (
      false,
      'Hi! ${widget.driver.name} here. On my way, see you in a few minutes.',
    ),
  ];
  final _input = TextEditingController();

  static const _quickReplies = [
    'I\'m outside',
    'Use the side entrance',
    'It\'s on the 3rd floor',
  ];

  void _send(String text) {
    if (text.trim().isEmpty) return;
    setState(() => _messages.add((true, text.trim())));
    _input.clear();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _messages.add((false, 'Got it, thanks!')));
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: Column(
            children: [
              Text(
                'Message ${widget.driver.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    for (final (mine, text) in _messages)
                      Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: mine
                                ? MovrColors.orange
                                : MovrColors.background,
                            borderRadius: kBorderRadius,
                          ),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: mine ? Colors.white : MovrColors.black,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final q in _quickReplies)
                    ActionChip(label: Text(q), onPressed: () => _send(q)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _input,
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: MovrColors.orange),
                    onPressed: () => _send(_input.text),
                  ),
                ),
                onSubmitted: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
