import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// The phone's GPS position (in a browser, the browser's location, which
/// asks the person for permission first and needs HTTPS).
class DeviceLocation {
  /// Asks for permission if needed. Null if location is off or refused.
  static Future<LatLng?> current() async {
    if (!await _allowed()) return null;
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Position updates as the phone moves (every 10 m or so). Ends with an
  /// error if permission is refused.
  static Stream<LatLng> watch() async* {
    if (!await _allowed()) {
      throw const LocationUnavailable();
    }
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).map((p) => LatLng(p.latitude, p.longitude));
  }

  static Future<bool> _allowed() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }
}

class LocationUnavailable implements Exception {
  const LocationUnavailable();
  @override
  String toString() => 'Location is off or permission was refused.';
}
