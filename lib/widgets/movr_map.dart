import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/routing.dart';
import '../theme.dart';

/// A real street map (OpenStreetMap tiles, softened towards grey to suit the
/// design guide). It opens fitted to [fit], keeping
/// clear of the screen area covered by UI ([padding]); people can pan and
/// zoom. [layers] are flutter_map layers drawn on top (routes, markers).
///
/// Production: swap for Google Maps (google_maps_flutter) once there is an
/// API key; the screens only depend on this widget.
class MovrMap extends StatelessWidget {
  const MovrMap({
    super.key,
    required this.fit,
    this.padding = EdgeInsets.zero,
    this.layers = const [],
    this.maxZoom = 15.5,
  });

  final List<LatLng> fit;
  final EdgeInsets padding;
  final List<Widget> layers;
  final double maxZoom;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: fit,
          padding: padding + const EdgeInsets.all(28),
          maxZoom: maxZoom,
        ),
        minZoom: 10,
        maxZoom: 18,
        backgroundColor: const Color(0xFFEDEDEB),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          // Standard OpenStreetMap tiles: free, no key. Softened to grey so
          // the orange and black UI stands out, per the design guide.
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.movr.movr',
          tileBuilder: (context, tile, _) =>
              ColorFiltered(colorFilter: _softGrey, child: tile),
        ),
        ...layers,
        _Attribution(bottom: padding.bottom),
      ],
    );
  }
}

/// Mostly desaturated and slightly lightened.
const _softGrey = ColorFilter.matrix(<double>[
  0.45,
  0.45,
  0.10,
  0,
  18,
  0.30,
  0.60,
  0.10,
  0,
  18,
  0.30,
  0.45,
  0.25,
  0,
  18,
  0,
  0,
  0,
  1,
  0,
]);

class _Attribution extends StatelessWidget {
  const _Attribution({required this.bottom});

  /// Sits just above the UI covering the bottom of the map.
  final double bottom;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomLeft,
    child: Container(
      margin: EdgeInsets.only(left: 6, bottom: bottom + 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        '© OpenStreetMap contributors',
        style: TextStyle(fontSize: 9, color: MovrColors.textMuted),
      ),
    ),
  );
}

/// A route line; dashed for the leg a driver is still approaching on.
Widget routeLayer(
  List<LatLng> points, {
  Color color = MovrColors.black,
  bool dashed = false,
}) {
  return PolylineLayer(
    polylines: [
      Polyline(
        points: points,
        color: color,
        strokeWidth: 5,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
        pattern: dashed
            ? StrokePattern.dashed(segments: const [10, 8])
            : const StrokePattern.solid(),
      ),
    ],
  );
}

/// A marker centred on [at] (or standing on it, for pins).
Marker mapMarker(
  LatLng at,
  Widget child, {
  double size = 32,
  bool anchorBottom = false,
}) => Marker(
  point: at,
  width: size,
  height: size,
  alignment: anchorBottom ? Alignment.topCenter : Alignment.center,
  child: child,
);

/// Little black truck icon; flips to face its direction of travel.
class TruckIcon extends StatelessWidget {
  const TruckIcon({
    super.key,
    this.facingLeft = false,
    this.highlighted = false,
  });
  final bool facingLeft;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MovrColors.black,
        borderRadius: BorderRadius.circular(9),
        border: highlighted
            ? Border.all(color: MovrColors.orange, width: 2.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Transform.flip(
        flipX: facingLeft,
        child: const Icon(Icons.local_shipping, color: Colors.white, size: 17),
      ),
    );
  }
}

class PickupPin extends StatelessWidget {
  const PickupPin({super.key});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: MovrColors.black,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: kFloatingShadow,
    ),
    child: const Center(
      child: CircleAvatar(radius: 3.5, backgroundColor: Colors.white),
    ),
  );
}

class DropoffPin extends StatelessWidget {
  const DropoffPin({super.key});
  @override
  Widget build(BuildContext context) => const Icon(
    Icons.location_on,
    color: MovrColors.orange,
    size: 40,
    shadows: [
      Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
    ],
  );
}

/// Loads the road route between two points; shows a straight line until it
/// arrives (or if routing is unavailable).
class RouteBuilder extends StatefulWidget {
  const RouteBuilder({super.key, required this.legs, required this.builder});

  /// Pairs of points to route between.
  final List<(LatLng, LatLng)> legs;
  final Widget Function(
    BuildContext context,
    List<List<LatLng>> routes,
    bool loaded,
  )
  builder;

  @override
  State<RouteBuilder> createState() => _RouteBuilderState();
}

class _RouteBuilderState extends State<RouteBuilder> {
  late List<List<LatLng>> _routes = [
    for (final (a, b) in widget.legs) [a, b],
  ];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(RouteBuilder old) {
    super.didUpdateWidget(old);
    if (old.legs.toString() != widget.legs.toString()) {
      _routes = [
        for (final (a, b) in widget.legs) [a, b],
      ];
      _loaded = false;
      _load();
    }
  }

  Future<void> _load() async {
    final legs = widget.legs;
    final routes = await Future.wait([for (final (a, b) in legs) _route(a, b)]);
    if (mounted && legs == widget.legs) {
      setState(() {
        _routes = routes;
        _loaded = true;
      });
    }
  }

  Future<List<LatLng>> _route(LatLng a, LatLng b) => Routing.route(a, b);

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _routes, _loaded);
}
