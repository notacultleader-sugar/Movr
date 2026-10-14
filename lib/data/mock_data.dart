import 'package:flutter/material.dart';

import '../models/move.dart';

/// Mock data standing in for the backend: places, listings, partner stores,
/// scannable items and drivers. Map positions sit on road intersections
/// (x and y each one of [kRoadLines]).
const kRoadLines = <double>[90, 240, 390, 530, 680, 830, 950];

const currentLocation = Place(
  'Current location',
  '1180 Granville St',
  Offset(390, 530),
);

const recentDropoff = Place('Home', '2450 Cedar Ave, Apt 3B', Offset(830, 240));

const suggestedPlaces = <Place>[
  recentDropoff,
  Place('Storage Hub', '88 Industrial Way, Unit 14', Offset(950, 830)),
  Place('Maple Court Apartments', '615 Maple St', Offset(680, 90)),
  Place('Riverside Lofts', '300 Riverside Dr', Offset(90, 680)),
  Place('Mom\'s place', '17 Birch Crescent', Offset(240, 950)),
  Place('Westgate Office Park', '400 Westgate Blvd', Offset(90, 240)),
];

class MarketplaceListing {
  const MarketplaceListing(
    this.title,
    this.source,
    this.price,
    this.place,
    this.item,
  );
  final String title;
  final String source;
  final String price;
  final Place place;
  final MoveItem item;
}

const sofa = MoveItem('Sofa', WeightClass.heavy, Icons.weekend);
const tv = MoveItem('TV (55")', WeightClass.medium, Icons.tv);
const bedFrame = MoveItem('Bed frame', WeightClass.heavy, Icons.bed);
const dresser = MoveItem('Dresser', WeightClass.heavy, Icons.table_bar);
const armchair = MoveItem('Armchair', WeightClass.medium, Icons.chair);
const boxes = MoveItem('Moving boxes', WeightClass.light, Icons.inventory_2);
const fridge = MoveItem('Refrigerator', WeightClass.extraHeavy, Icons.kitchen);
const desk = MoveItem('Desk', WeightClass.medium, Icons.desk);

/// Order the simulated AI scanner "detects" items in.
const scannableItems = <MoveItem>[
  sofa,
  tv,
  bedFrame,
  dresser,
  armchair,
  boxes,
  fridge,
  desk,
];

const marketplaceListings = <MarketplaceListing>[
  MarketplaceListing(
    'Grey sectional sofa, like new',
    'Facebook Marketplace',
    '\$350',
    Place('Seller: Jenna R.', '742 Oak St', Offset(240, 390)),
    sofa,
  ),
  MarketplaceListing(
    'Solid wood dresser, 6 drawers',
    'Craigslist',
    '\$120',
    Place('Seller: Dan K.', '1290 Pine Ave', Offset(530, 680)),
    dresser,
  ),
  MarketplaceListing(
    'Samsung 55" smart TV',
    'Facebook Marketplace',
    '\$200',
    Place('Seller: Alex M.', '55 Harbour Rd', Offset(680, 830)),
    tv,
  ),
  MarketplaceListing(
    'Mid-century armchair',
    'Craigslist',
    '\$90',
    Place('Seller: Sam T.', '9 Elm Lane', Offset(390, 90)),
    armchair,
  ),
];

class PartnerStore {
  const PartnerStore(this.place, this.blurb);
  final Place place;
  final String blurb;
}

const partnerStores = <PartnerStore>[
  PartnerStore(
    Place('Second Chance Thrift', '210 Market St', Offset(530, 390)),
    'Furniture & home goods · Partner since 2026',
  ),
  PartnerStore(
    Place('Oak & Ember Vintage', '48 Commercial Dr', Offset(240, 680)),
    'Mid-century furniture',
  ),
  PartnerStore(
    Place('The Furniture Exchange', '1500 Main St', Offset(830, 530)),
    'Consignment sofas, beds, tables',
  ),
];

const drivers = <VehicleTier, Driver>{
  VehicleTier.haul: Driver(
    name: 'Marcus',
    rating: 4.9,
    vehicle: 'Black Ford F-150',
    plate: 'BJK-992',
    phone: '(555) 014-2290',
  ),
  VehicleTier.van: Driver(
    name: 'Priya',
    rating: 4.8,
    vehicle: 'White Ford Transit',
    plate: 'KLM-417',
    phone: '(555) 014-7781',
  ),
};

/// Intersections a matched driver might be waiting at.
const _driverSpots = <Offset>[
  Offset(90, 90),
  Offset(950, 90),
  Offset(90, 950),
  Offset(950, 950),
  Offset(530, 90),
  Offset(90, 530),
];

/// Where the assigned driver starts: a spot roughly "4 minutes" (about 450
/// map units by road) from the pickup.
Offset driverStartFor(Offset pickup) {
  double score(Offset s) =>
      ((s.dx - pickup.dx).abs() + (s.dy - pickup.dy).abs() - 450).abs();
  return _driverSpots.reduce((a, b) => score(a) <= score(b) ? a : b);
}
