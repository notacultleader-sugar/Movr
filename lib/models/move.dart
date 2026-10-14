import 'dart:math' as math;

import 'package:flutter/material.dart' show IconData;
import 'package:latlong2/latlong.dart';

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

/// Service tiers shown in the vehicle toggle. Haul and Van are a driver
/// with their vehicle; Muscle is labour only (the customer has a vehicle),
/// priced per helper per hour.
enum VehicleTier {
  haul('Haul', 'Pickup', 45, 'Great for a Couch or TV.'),
  van('Van', 'Cargo', 75, 'Great for a Studio or Bed frame.'),
  muscle('Muscle', 'Labour only', 50, 'Helpers only. You bring the vehicle.');

  const VehicleTier(this.name, this.vehicleType, this.basePrice, this.tagline);
  final String name;
  final String vehicleType;

  /// Flat base price, or for Muscle the rate per helper per hour.
  final double basePrice;
  final String tagline;

  bool get laborOnly => this == muscle;
  String get priceLabel => laborOnly
      ? '${money(basePrice).replaceAll('.00', '')}/hr'
      : '${money(basePrice).replaceAll('.00', '')} base';
}

/// A named location on the map.
class Place {
  const Place(this.name, this.address, this.pos);
  final String name;
  final String address;
  final LatLng pos;
}

/// Pricing rules for a move:
///   tier base price + per-item weight surcharge + extra-mile fee + safety fee.
/// The first [includedMiles] are in the base price.
///
/// Muscle (labour only) is instead helpers x hours x hourly rate + safety
/// fee: the customer drives, so there is no distance fee, and the hourly
/// rate covers handling, so there is no item surcharge.
class Quote {
  const Quote({
    required this.vehicle,
    required this.items,
    required this.miles,
    this.helpers = 1,
    this.hours = 1,
  });

  static const double safetyFee = 10.00;
  static const double includedMiles = 5;
  static const double perExtraMile = 2.00;

  final VehicleTier vehicle;
  final List<MoveItem> items;
  final double miles;

  /// Muscle only.
  final int helpers;
  final int hours;

  double get basePrice => vehicle.laborOnly
      ? vehicle.basePrice * helpers * hours
      : vehicle.basePrice;
  double get itemsFee => vehicle.laborOnly
      ? 0
      : items.fold(0.0, (sum, i) => sum + i.weightClass.surcharge);
  double get distanceFee =>
      vehicle.laborOnly ? 0 : math.max(0, miles - includedMiles) * perExtraMile;
  double get total => basePrice + itemsFee + distanceFee + safetyFee;

  Quote copyWith({
    VehicleTier? vehicle,
    List<MoveItem>? items,
    int? helpers,
    int? hours,
  }) => Quote(
    vehicle: vehicle ?? this.vehicle,
    items: items ?? this.items,
    miles: miles,
    helpers: helpers ?? this.helpers,
    hours: hours ?? this.hours,
  );
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
  final LatLng driverStart;
}

const _distance = Distance();
const double _metersPerMile = 1609.34;

/// Roads wind, so a straight-line distance is scaled up to estimate the
/// driving distance until a real route comes back.
const double _roadFactor = 1.3;

double metersBetween(LatLng a, LatLng b) => _distance(a, b);

double pathMeters(List<LatLng> path) {
  var total = 0.0;
  for (var i = 1; i < path.length; i++) {
    total += metersBetween(path[i - 1], path[i]);
  }
  return total;
}

/// Estimated driving miles between two places, to one decimal.
double routeMiles(LatLng a, LatLng b) =>
    (metersBetween(a, b) * _roadFactor / _metersPerMile * 10).roundToDouble() /
    10;

/// Point at fraction [t] (0..1) of the way along [path], by distance.
LatLng pointAlong(List<LatLng> path, double t) {
  if (path.length < 2) return path.first;
  final total = pathMeters(path);
  if (total == 0) return path.first;
  var remaining = t.clamp(0.0, 1.0) * total;
  for (var i = 1; i < path.length; i++) {
    final a = path[i - 1], b = path[i];
    final seg = metersBetween(a, b);
    if (remaining <= seg) {
      final f = seg == 0 ? 0.0 : remaining / seg;
      return LatLng(
        a.latitude + (b.latitude - a.latitude) * f,
        a.longitude + (b.longitude - a.longitude) * f,
      );
    }
    remaining -= seg;
  }
  return path.last;
}

String money(double v) => '\$${v.toStringAsFixed(2)}';

/// What a driver earns from one move. The platform keeps [commissionRate] of
/// the fare; the safety fee covers insurance and checks; tips go 100% to the
/// driver.
class DriverPayout {
  const DriverPayout(this.quote, {this.tip = 0});

  static const double commissionRate = 0.25;

  final Quote quote;
  final double tip;

  double get fare => quote.total - Quote.safetyFee;
  double get commission => (fare * commissionRate * 100).round() / 100;
  double get total => fare - commission + tip;
}
