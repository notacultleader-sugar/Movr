import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flutter/material.dart' show IconData;

/// Weight classes the AI scanner assigns to an item. Each adds a handling
/// surcharge to the quote.
enum WeightClass {
  light('Light', 'Under 50 lb', 2.50),
  medium('Medium', '50–150 lb', 5.00),
  heavy('Heavy', '150–250 lb', 7.50),
  extraHeavy('Extra heavy', '250+ lb', 12.50);

  const WeightClass(this.label, this.range, this.surcharge);
  final String label;
  final String range;
  final double surcharge;
}

class MoveItem {
  const MoveItem(this.name, this.weightClass, this.icon);
  final String name;
  final WeightClass weightClass;
  final IconData icon;
}

/// Service tiers shown in the vehicle toggle.
enum VehicleTier {
  haul('Haul', 'Pickup', 45, 'Great for a Couch or TV.'),
  van('Van', 'Cargo', 75, 'Great for a Studio or Bed frame.');

  const VehicleTier(this.name, this.vehicleType, this.basePrice, this.tagline);
  final String name;
  final String vehicleType;
  final double basePrice;
  final String tagline;
}

/// A location on the prototype map. [mapPos] is in the map's 1000x1000
/// world space and always sits on a road intersection.
class Place {
  const Place(this.name, this.address, this.mapPos);
  final String name;
  final String address;
  final Offset mapPos;
}

/// Pricing rules for a move:
///   tier base price + per-item weight surcharge + extra-mile fee + safety fee.
/// The first [includedMiles] are in the base price.
class Quote {
  const Quote({required this.vehicle, required this.items, required this.miles});

  static const double safetyFee = 10.00;
  static const double includedMiles = 5;
  static const double perExtraMile = 2.00;

  final VehicleTier vehicle;
  final List<MoveItem> items;
  final double miles;

  double get basePrice => vehicle.basePrice;
  double get itemsFee => items.fold(0.0, (sum, i) => sum + i.weightClass.surcharge);
  double get distanceFee => math.max(0, miles - includedMiles) * perExtraMile;
  double get total => basePrice + itemsFee + distanceFee + safetyFee;

  Quote copyWith({VehicleTier? vehicle, List<MoveItem>? items}) =>
      Quote(vehicle: vehicle ?? this.vehicle, items: items ?? this.items, miles: miles);
}

class Driver {
  const Driver({
    required this.name,
    required this.rating,
    required this.vehicle,
    required this.plate,
    required this.phone,
  });
  final String name;
  final double rating;
  final String vehicle;
  final String plate;
  final String phone;

  String get initials => name.substring(0, 1);
}

/// Everything about one booked move, passed from screen to screen.
class MoveOrder {
  const MoveOrder({
    required this.pickup,
    required this.dropoff,
    required this.quote,
    required this.driver,
    required this.driverStart,
  });
  final Place pickup;
  final Place dropoff;
  final Quote quote;
  final Driver driver;
  final Offset driverStart;
}

/// Map world units to miles. A cross-town trip of ~700 units is ~4.2 miles.
const double kMilesPerMapUnit = 0.006;

/// Road route between two intersections: along [a]'s street, then [b]'s.
List<Offset> roadRoute(Offset a, Offset b) => [a, Offset(b.dx, a.dy), b];

double pathLength(List<Offset> path) {
  var total = 0.0;
  for (var i = 1; i < path.length; i++) {
    total += (path[i] - path[i - 1]).distance;
  }
  return total;
}

double routeMiles(Offset a, Offset b) =>
    (pathLength(roadRoute(a, b)) * kMilesPerMapUnit * 10).roundToDouble() / 10;

/// Point at fraction [t] (0..1) of the way along [path].
Offset pointAlong(List<Offset> path, double t) {
  final total = pathLength(path);
  if (total == 0) return path.first;
  var remaining = t.clamp(0.0, 1.0) * total;
  for (var i = 1; i < path.length; i++) {
    final seg = path[i] - path[i - 1];
    if (remaining <= seg.distance) {
      return path[i - 1] + seg * (seg.distance == 0 ? 0 : remaining / seg.distance);
    }
    remaining -= seg.distance;
  }
  return path.last;
}

String money(double v) => '\$${v.toStringAsFixed(2)}';
