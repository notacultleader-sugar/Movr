import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/move.dart';

/// Address search and reverse lookup from OpenStreetMap's Nominatim service.
///
/// Free and keyless, but limited to light use (about one request a second),
/// which is fine for a pilot. Results are biased to the Cowichan Valley and
/// southern Vancouver Island. Production: Google Places with an API key.
class Geocoding {
  Geocoding({http.Client? client}) : _client = client ?? http.Client();

  static final instance = Geocoding();

  static const _base = 'https://nominatim.openstreetmap.org';

  /// Southern Vancouver Island: west, north, east, south.
  static const _viewbox = '-124.4,49.2,-123.2,48.3';

  final http.Client _client;

  /// Places matching [query], best first. Empty on any error.
  Future<List<Place>> search(String query) async {
    final q = query.trim();
    if (q.length < 3) return const [];
    final url = Uri.parse(
      '$_base/search?format=jsonv2&addressdetails=1&limit=6'
      '&countrycodes=ca&viewbox=$_viewbox'
      '&q=${Uri.encodeQueryComponent(q)}',
    );
    try {
      final res = await _client.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const [];
      final list = jsonDecode(res.body) as List;
      return [for (final r in list) _place(r as Map<String, dynamic>)];
    } catch (_) {
      return const [];
    }
  }

  /// The street address at [pos], or null if it can't be found.
  Future<Place?> reverse(LatLng pos, {String name = 'Current location'}) async {
    final url = Uri.parse(
      '$_base/reverse?format=jsonv2&addressdetails=1&zoom=18'
      '&lat=${pos.latitude}&lon=${pos.longitude}',
    );
    try {
      final res = await _client.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final r = jsonDecode(res.body) as Map<String, dynamic>;
      if (r.containsKey('error')) return null;
      final p = _place(r);
      return Place(name, p.address, pos);
    } catch (_) {
      return null;
    }
  }

  static Place _place(Map<String, dynamic> r) {
    final a = (r['address'] as Map?)?.cast<String, dynamic>() ?? const {};
    final street = [a['house_number'], a['road']].whereType<String>().join(' ');
    final town =
        (a['city'] ??
                a['town'] ??
                a['village'] ??
                a['hamlet'] ??
                a['municipality'])
            as String?;
    final display = r['display_name'] as String? ?? '';
    final named = r['name'] as String?;
    final name = (named != null && named.isNotEmpty)
        ? named
        : (street.isNotEmpty ? street : display.split(',').first);
    // Don't repeat the street when it is already the place's name.
    final address = [
      if (street.isNotEmpty && street != name) street,
      ?town,
    ].join(', ');
    return Place(
      name,
      address.isNotEmpty ? address : display,
      LatLng(
        double.parse(r['lat'].toString()),
        double.parse(r['lon'].toString()),
      ),
    );
  }
}
