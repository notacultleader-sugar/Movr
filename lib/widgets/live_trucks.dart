import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/move.dart';
import 'city_map.dart';

/// Simulated "Live Trucks": each truck drives a loop of roads around a few
/// blocks. A real build would stream driver GPS positions instead.
class LiveTrucksLayer extends StatefulWidget {
  const LiveTrucksLayer({super.key, required this.projection});
  final MapProjection projection;

  @override
  State<LiveTrucksLayer> createState() => _LiveTrucksLayerState();
}

class _Loop {
  _Loop(int x1, int y1, int x2, int y2, this.phase, this.laps)
    : path = [
        Offset(kRoadLines[x1], kRoadLines[y1]),
        Offset(kRoadLines[x2], kRoadLines[y1]),
        Offset(kRoadLines[x2], kRoadLines[y2]),
        Offset(kRoadLines[x1], kRoadLines[y2]),
        Offset(kRoadLines[x1], kRoadLines[y1]),
      ];
  final List<Offset> path;
  final double phase;
  final int laps; // laps per animation cycle; sets the truck's speed
}

class _LiveTrucksLayerState extends State<LiveTrucksLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 90),
  )..repeat();

  static final _loops = [
    _Loop(1, 1, 3, 2, 0.0, 3),
    _Loop(2, 3, 4, 5, 0.3, 2),
    _Loop(4, 1, 5, 3, 0.6, 3),
    _Loop(0, 4, 2, 6, 0.15, 2),
    _Loop(3, 2, 5, 4, 0.8, 2),
    _Loop(5, 4, 6, 6, 0.45, 3),
    _Loop(1, 0, 4, 1, 0.7, 2),
    _Loop(2, 5, 3, 6, 0.25, 3),
  ];

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _clock,
      builder: (context, _) =>
          Stack(children: [for (final loop in _loops) _truck(loop)]),
    );
  }

  Widget _truck(_Loop loop) {
    final t = (_clock.value * loop.laps + loop.phase) % 1.0;
    final pos = pointAlong(loop.path, t);
    final ahead = pointAlong(loop.path, (t + 0.002) % 1.0);
    return MapMarker(
      projection: widget.projection,
      at: pos,
      size: 30,
      child: TruckIcon(facingLeft: ahead.dx < pos.dx - 0.01),
    );
  }
}

const liveTruckCount = 8;
