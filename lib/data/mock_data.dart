import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/move.dart';

/// Mock data standing in for the backend: places, listings, partner stores,
/// scannable items and drivers, set around Duncan in the Cowichan Valley.
/// Names and street numbers are samples; positions are approximate.
const duncanCentre = LatLng(48.7787, -123.7079);

const currentLocation = Place(
  'Current location',
  '135 Station St, Duncan',
  LatLng(48.7782, -123.7081),
);

const recentDropoff = Place(
  'Home',
  '2450 Lakes Rd, Duncan',
  LatLng(48.7935, -123.6905),
);

const suggestedPlaces = <Place>[
  recentDropoff,
  Place(
    'Storage Hub',
    'Unit 14, 6200 Trans-Canada Hwy',
    LatLng(48.8000, -123.7120),
  ),
  Place(
    'Maple Court Apartments',
    '615 Maple Bay Rd',
    LatLng(48.7960, -123.6960),
  ),
  Place('Riverside Lofts', '300 Canada Ave', LatLng(48.7745, -123.7060)),
  Place('Mom\'s place', '17 Tzouhalem Rd', LatLng(48.7840, -123.6800)),
  Place('Westgate Office Park', '400 Trunk Rd', LatLng(48.7760, -123.7180)),
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

const sofa = MoveItem('Sofa', ItemSize.large, Icons.weekend);
const tv = MoveItem('TV (55")', ItemSize.medium, Icons.tv);
const bedFrame = MoveItem('Bed frame', ItemSize.large, Icons.bed);
const dresser = MoveItem('Dresser', ItemSize.large, Icons.table_bar);
const armchair = MoveItem('Armchair', ItemSize.medium, Icons.chair);
const boxes = MoveItem('Moving boxes', ItemSize.small, Icons.inventory_2);
const fridge = MoveItem('Refrigerator', ItemSize.extraLarge, Icons.kitchen);
const desk = MoveItem('Desk', ItemSize.medium, Icons.desk);

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
    Place('Seller: Jenna R.', '742 Beverly St', LatLng(48.7860, -123.7120)),
    sofa,
  ),
  MarketplaceListing(
    'Solid wood dresser, 6 drawers',
    'Craigslist',
    '\$120',
    Place('Seller: Dan K.', '1290 Herd Rd', LatLng(48.8150, -123.7000)),
    dresser,
  ),
  MarketplaceListing(
    'Samsung 55" smart TV',
    'Facebook Marketplace',
    '\$200',
    Place('Seller: Alex M.', '55 Allenby Rd', LatLng(48.7690, -123.7170)),
    tv,
  ),
  MarketplaceListing(
    'Mid-century armchair',
    'Craigslist',
    '\$90',
    Place('Seller: Sam T.', '9 Jubilee St', LatLng(48.7820, -123.7040)),
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
    Place(
      'Second Chance Thrift',
      '210 Government St',
      LatLng(48.7810, -123.7065),
    ),
    'Furniture & home goods · Partner since 2026',
  ),
  PartnerStore(
    Place('Oak & Ember Vintage', '48 Kenneth St', LatLng(48.7792, -123.7095)),
    'Mid-century furniture',
  ),
  PartnerStore(
    Place(
      'The Furniture Exchange',
      '1500 Cowichan Way',
      LatLng(48.7700, -123.6990),
    ),
    'Consignment sofas, beds, tables',
  ),
];

const drivers = <VehicleTier, Driver>{
  VehicleTier.truck: Driver(
    name: 'Marcus',
    rating: 4.9,
    vehicle: 'Black Ford F-150',
    plate: 'BJK-992',
    phone: '(555) 014-2290',
  ),
  // Muscle helpers arrive in their own car and ride along to the drop-off.
  VehicleTier.muscle: Driver(
    name: 'Devon',
    rating: 4.9,
    vehicle: 'Helper · Grey Honda Civic',
    plate: 'HLP-305',
    phone: '(555) 014-3318',
  ),
};

/// Where matched drivers might be waiting.
const _driverSpots = <LatLng>[
  LatLng(48.7700, -123.7200),
  LatLng(48.7950, -123.7200),
  LatLng(48.7700, -123.6850),
  LatLng(48.7950, -123.6850),
  LatLng(48.8050, -123.7000),
  LatLng(48.7650, -123.7050),
];

/// Where the assigned driver starts: a spot roughly "4 minutes" (about 2 km)
/// from the pickup.
LatLng driverStartFor(LatLng pickup) {
  double score(LatLng s) => (metersBetween(s, pickup) - 2000).abs();
  return _driverSpots.reduce((a, b) => score(a) <= score(b) ? a : b);
}

/// Pairs of places the simulated "live trucks" drive between.
const liveTruckRoutes = <(LatLng, LatLng)>[
  (LatLng(48.7700, -123.7200), LatLng(48.8000, -123.7120)),
  (LatLng(48.7782, -123.7081), LatLng(48.7935, -123.6905)),
  (LatLng(48.7650, -123.7050), LatLng(48.7860, -123.7120)),
  (LatLng(48.7840, -123.6800), LatLng(48.7745, -123.7060)),
  (LatLng(48.8050, -123.7000), LatLng(48.7810, -123.7065)),
  (LatLng(48.7700, -123.6990), LatLng(48.7960, -123.6960)),
  (LatLng(48.7690, -123.7170), LatLng(48.7820, -123.7040)),
  (LatLng(48.8150, -123.7000), LatLng(48.7950, -123.7200)),
];
