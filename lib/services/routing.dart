import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Driving routes along real roads, from the public OSRM demo server
/// (OpenStreetMap data). Good enough for the prototype; production should
/// use Google's Routes API or a hosted OSRM with an agreement.
///
/// Never throws: if the server can't be reached, the route is a straight
/// line between the two points so the app keeps working.
class Routing {
  static const _base = 'https://router.project-osrm.org/route/v1/driving';
  static final Map<String, Future<List<LatLng>>> _cache = {};

  static Future<List<LatLng>> route(LatLng from, LatLng to) {
    final key =
        '${from.latitude},${from.longitude};${to.latitude},${to.longitude}';
    return _cache.putIfAbsent(key, () => _fetch(from, to));
  }

  static Future<List<LatLng>> _fetch(LatLng from, LatLng to) async {
    final url = Uri.parse(
      '$_base/${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson',
    );
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return [from, to];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final coords =
          ((body['routes'] as List).first
                  as Map<String, dynamic>)['geometry']['coordinates']
              as List;
      final points = [
        for (final c in coords)
          LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
      ];
      // Start and end exactly at the pins, not the nearest road point.
      return points.length < 2 ? [from, to] : [from, ...points, to];
    } catch (_) {
      return [from, to];
    }
  }
}
