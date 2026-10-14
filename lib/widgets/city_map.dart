import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme.dart';

/// Converts the map's 1000x1000 world coordinates to screen pixels, fitting
/// [focus] into the part of the widget not covered by [padding].
class MapProjection {
  MapProjection(Size size, Rect focus, EdgeInsets padding) {
    final avail = padding.deflateRect(Offset.zero & size);
    scale = math.min(avail.width / focus.width, avail.height / focus.height);
    _screenCenter = avail.center;
    _worldCenter = focus.center;
  }

  late final double scale;
  late final Offset _screenCenter;
  late final Offset _worldCenter;

  Offset toScreen(Offset world) =>
      _screenCenter + (world - _worldCenter) * scale;
  Offset toWorld(Offset screen) =>
      _worldCenter + (screen - _screenCenter) / scale;
}

/// A stylised, self-drawn city map. It stands in for Google Maps in the
/// prototype so the app runs with no API key or tile server.
class CityMap extends StatelessWidget {
  const CityMap({
    super.key,
    this.focus = const Rect.fromLTWH(150, 150, 700, 700),
    this.padding = EdgeInsets.zero,
    this.overlays,
  });

  final Rect focus;
  final EdgeInsets padding;
  final List<Widget> Function(MapProjection projection)? overlays;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final projection = MapProjection(size, focus, padding);
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(painter: _CityPainter(projection)),
              ),
              ...?overlays?.call(projection),
            ],
          ),
        );
      },
    );
  }
}

class _CityPainter extends CustomPainter {
  _CityPainter(this.p);
  final MapProjection p;

  static const _land = Color(0xFFEDEDEB);
  static const _building = Color(0xFFE2E2DF);
  static const _park = Color(0xFFD7EDD3);
  static const _water = Color(0xFFCFE0F0);
  static const _minorRoad = Color(0xFFFAFAFA);
  static const _majorRoad = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _land);

    final topLeft = p.toWorld(Offset.zero);
    final bottomRight = p.toWorld(size.bottomRight(Offset.zero));
    final visible = Rect.fromPoints(topLeft, bottomRight).inflate(60);

    // Buildings: small footprints inside each 75-unit block.
    final buildingPaint = Paint()..color = _building;
    const step = 75.0;
    for (
      var bx = (visible.left / step).floor() * step;
      bx < visible.right;
      bx += step
    ) {
      for (
        var by = (visible.top / step).floor() * step;
        by < visible.bottom;
        by += step
      ) {
        final r = math.Random((bx * 31 + by * 17).toInt());
        for (var k = 0; k < 2; k++) {
          final w = 18 + r.nextDouble() * 22;
          final h = 18 + r.nextDouble() * 22;
          final x = bx + 10 + r.nextDouble() * (step - w - 20);
          final y = by + 10 + r.nextDouble() * (step - h - 20);
          _rrect(canvas, Rect.fromLTWH(x, y, w, h), 3, buildingPaint);
        }
      }
    }

    // Parks.
    final parkPaint = Paint()..color = _park;
    for (final r in const [
      Rect.fromLTRB(250, 100, 380, 230),
      Rect.fromLTRB(540, 840, 670, 940),
      Rect.fromLTRB(690, 400, 820, 520),
      Rect.fromLTRB(100, 840, 230, 1000),
    ]) {
      _rrect(canvas, r, 10, parkPaint);
    }

    // Waterfront along the left edge.
    final water = Path()
      ..moveTo(-400, -400)
      ..lineTo(30, -400)
      ..cubicTo(55, 120, 15, 360, 45, 560)
      ..cubicTo(70, 760, 20, 980, 40, 1400)
      ..lineTo(-400, 1400)
      ..close();
    canvas.drawPath(water.transform(_matrix.storage), Paint()..color = _water);

    // Minor streets halfway between the major roads, then major roads.
    final minor = <double>[];
    for (var i = 1; i < kRoadLines.length; i++) {
      minor.add((kRoadLines[i - 1] + kRoadLines[i]) / 2);
    }
    _roads(canvas, minor, visible, 7, _minorRoad);
    _roads(canvas, kRoadLines, visible, 15, _majorRoad);

    // Diagonal avenue for some character.
    final avenue = Paint()
      ..color = _majorRoad
      ..strokeWidth = 13 * p.scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      p.toScreen(const Offset(390, 1100)),
      p.toScreen(const Offset(1100, 390)),
      avenue,
    );
  }

  Matrix4 get _matrix {
    final origin = p.toScreen(Offset.zero);
    return Matrix4.identity()
      ..translateByDouble(origin.dx, origin.dy, 0, 1)
      ..scaleByDouble(p.scale, p.scale, 1, 1);
  }

  void _rrect(Canvas canvas, Rect world, double radius, Paint paint) {
    final tl = p.toScreen(world.topLeft);
    final br = p.toScreen(world.bottomRight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(tl, br),
        Radius.circular(radius * p.scale),
      ),
      paint,
    );
  }

  void _roads(
    Canvas canvas,
    List<double> lines,
    Rect visible,
    double width,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width * p.scale;
    // Repeat the road grid beyond the 1000x1000 world so edges never look empty.
    for (final offset in const [-1000.0, 0.0, 1000.0]) {
      for (final v in lines) {
        final x = v + offset;
        if (x >= visible.left && x <= visible.right) {
          canvas.drawLine(
            p.toScreen(Offset(x, visible.top)),
            p.toScreen(Offset(x, visible.bottom)),
            paint,
          );
        }
        final y = v + offset;
        if (y >= visible.top && y <= visible.bottom) {
          canvas.drawLine(
            p.toScreen(Offset(visible.left, y)),
            p.toScreen(Offset(visible.right, y)),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CityPainter old) =>
      old.p.scale != p.scale ||
      old.p.toScreen(Offset.zero) != p.toScreen(Offset.zero);
}

/// Draws a route polyline in world coordinates.
class RouteLayer extends StatelessWidget {
  const RouteLayer({
    super.key,
    required this.projection,
    required this.path,
    this.color = MovrColors.black,
    this.dashed = false,
  });
  final MapProjection projection;
  final List<Offset> path;
  final Color color;
  final bool dashed;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(painter: _RoutePainter(projection, path, color, dashed)),
  );
}

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.p, this.path, this.color, this.dashed);
  final MapProjection p;
  final List<Offset> path;
  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;
    final pts = path.map(p.toScreen).toList();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (!dashed) {
      final line = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final pt in pts.skip(1)) {
        line.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(line, paint);
      return;
    }
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      final len = (b - a).distance;
      for (var d = 0.0; d < len; d += 14) {
        final s = a + (b - a) * (d / len);
        final e = a + (b - a) * (math.min(d + 7, len) / len);
        canvas.drawLine(s, e, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) => true;
}

/// A marker centred on a world position.
class MapMarker extends StatelessWidget {
  const MapMarker({
    super.key,
    required this.projection,
    required this.at,
    required this.child,
    this.size = 32,
    this.anchorBottom = false,
  });
  final MapProjection projection;
  final Offset at;
  final Widget child;
  final double size;
  final bool anchorBottom;

  @override
  Widget build(BuildContext context) {
    final s = projection.toScreen(at);
    return Positioned(
      left: s.dx - size / 2,
      top: anchorBottom ? s.dy - size : s.dy - size / 2,
      width: size,
      height: size,
      child: child,
    );
  }
}

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
