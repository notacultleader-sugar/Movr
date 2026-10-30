import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/move.dart';
import 'mock_data.dart';

/// A move offered to a driver.
class JobRequest {
  const JobRequest({
    required this.customer,
    required this.customerRating,
    required this.pickup,
    required this.dropoff,
    required this.items,
    required this.vehicle,
  });

  final String customer;
  final double customerRating;
  final Place pickup;
  final Place dropoff;
  final List<MoveItem> items;
  final VehicleTier vehicle;

  Quote get quote => Quote(
    vehicle: vehicle,
    items: items,
    miles: routeMiles(pickup.pos, dropoff.pos),
  );
  DriverPayout get payout => DriverPayout(quote);
}

/// Mock jobs, offered in turn. [vehicle] is replaced by the driver's tier.
const jobPool = <JobRequest>[
  JobRequest(
    customer: 'Ava',
    customerRating: 4.9,
    pickup: Place(
      'Second Chance Thrift',
      '210 Government St',
      LatLng(48.7810, -123.7065),
    ),
    dropoff: Place(
      'Maple Court Apartments',
      '615 Maple Bay Rd',
      LatLng(48.7960, -123.6960),
    ),
    items: [sofa],
    vehicle: VehicleTier.truck,
  ),
  JobRequest(
    customer: 'Ben',
    customerRating: 4.7,
    pickup: Place('Seller: Dan K.', '1290 Herd Rd', LatLng(48.8150, -123.7000)),
    dropoff: Place(
      'Riverside Lofts',
      '300 Canada Ave',
      LatLng(48.7745, -123.7060),
    ),
    items: [dresser, boxes],
    vehicle: VehicleTier.truck,
  ),
  JobRequest(
    customer: 'Chloe',
    customerRating: 5.0,
    pickup: Place(
      'The Furniture Exchange',
      '1500 Cowichan Way',
      LatLng(48.7700, -123.6990),
    ),
    dropoff: Place(
      'Storage Hub',
      'Unit 14, 6200 Trans-Canada Hwy',
      LatLng(48.8000, -123.7120),
    ),
    items: [bedFrame, armchair],
    vehicle: VehicleTier.truck,
  ),
];

enum DriverVehicleType {
  pickup('Pickup truck', Icons.local_shipping, VehicleTier.truck),
  cargoVan('Cargo van', Icons.airport_shuttle, VehicleTier.truck),
  boxTruck('Box truck', Icons.fire_truck, VehicleTier.truck);

  const DriverVehicleType(this.label, this.icon, this.tier);
  final String label;
  final IconData icon;
  final VehicleTier tier;
}

class CompletedTrip {
  const CompletedTrip(this.job, this.payout, this.when);
  final JobRequest job;
  final DriverPayout payout;
  final String when;
}

/// The signed-in driver's profile and earnings for the demo. Sign-up fills
/// the profile; finished jobs add to today's earnings.
class DriverSession extends ChangeNotifier {
  String name = 'Marcus';
  double rating = 4.9;
  DriverVehicleType vehicleType = DriverVehicleType.pickup;
  String vehicle = 'Black Ford F-150';
  String plate = 'BJK-992';

  /// Earnings earlier this week (Mon..Sun), before today's trips.
  static const weekBefore = <double>[86.40, 142.10, 0, 118.75, 64.20, 0, 0];
  static const todayIndex = 4; // Friday

  final List<CompletedTrip> todayTrips = [];
  int _nextJob = 0;

  double get todayEarnings =>
      todayTrips.fold(0.0, (s, t) => s + t.payout.total);

  List<double> get week => [
    for (var i = 0; i < weekBefore.length; i++)
      weekBefore[i] + (i == todayIndex ? todayEarnings : 0),
  ];

  double get weekTotal => week.fold(0.0, (a, b) => a + b);

  double cashedOut = 0;
  double get available => todayEarnings - cashedOut;

  JobRequest nextJob() {
    final base = jobPool[_nextJob++ % jobPool.length];
    return JobRequest(
      customer: base.customer,
      customerRating: base.customerRating,
      pickup: base.pickup,
      dropoff: base.dropoff,
      items: base.items,
      vehicle: vehicleType.tier,
    );
  }

  void register({
    required String name,
    required DriverVehicleType type,
    required String vehicle,
    required String plate,
  }) {
    this.name = name;
    vehicleType = type;
    this.vehicle = vehicle;
    this.plate = plate;
    rating = 5.0;
    notifyListeners();
  }

  void completeTrip(JobRequest job, DriverPayout payout) {
    todayTrips.insert(0, CompletedTrip(job, payout, 'Today'));
    notifyListeners();
  }

  void cashOut() {
    cashedOut = todayEarnings;
    notifyListeners();
  }
}

final driverSession = DriverSession();

/// Where the demo driver is parked while waiting for jobs (downtown Duncan).
const driverHomeSpot = LatLng(48.7770, -123.7110);
