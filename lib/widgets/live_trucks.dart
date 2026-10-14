import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/mock_data.dart';
import '../models/move.dart';
import '../services/routing.dart';
import 'movr_map.dart';

/// Simulated "Live Trucks": each truck drives back and forth along a real
/// road route around Duncan. A real build would stream driver GPS instead.
class LiveTrucksLayer extends StatefulWidget {
  const LiveTrucksLayer({super.key});

  @override
  State<LiveTrucksLayer> createState() => _LiveTrucksLayerState();
}

class _LiveTrucksLayerState extends State<LiveTrucksLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 120),
  )..repeat();

  late List<List<LatLng>> _routes = [
    for (final (a, b) in liveTruckRoutes) [a, b],
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final routes = await Future.wait([
      for (final (a, b) in liveTruckRoutes) Routing.route(a, b),
    ]);
    if (mounted) setState(() => _routes = routes);
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _clock,
      builder: (context, _) => MarkerLayer(
        markers: [for (var i = 0; i < _routes.length; i++) _truck(i)],
      ),
    );
  }

  Marker _truck(int i) {
    final path = _routes[i];
    // Each truck has its own speed and starting point; it drives the route
    // out and back so it never jumps.
    final laps = 2 + i % 2;
    final t = (_clock.value * laps + i * 0.137) % 1.0;
    final there = t < 0.5;
    final u = there ? t * 2 : (1 - t) * 2;
    final pos = pointAlong(path, u);
    final ahead = pointAlong(path, (u + (there ? 0.01 : -0.01)).clamp(0, 1));
    return mapMarker(
      pos,
      TruckIcon(facingLeft: ahead.longitude < pos.longitude),
      size: 30,
    );
  }
}

const liveTruckCount = 8;
