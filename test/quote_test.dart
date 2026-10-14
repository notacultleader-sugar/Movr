import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:movr/data/mock_data.dart';
import 'package:movr/models/move.dart';

void main() {
  test('Haul with a sofa matches the spec price of \$62.50', () {
    const quote = Quote(vehicle: VehicleTier.haul, items: [sofa], miles: 4.2);
    expect(quote.total, 62.50); // 45 base + 7.50 heavy item + 10 safety fee
  });

  test('Van base is \$75 plus the safety fee', () {
    const quote = Quote(vehicle: VehicleTier.van, items: [], miles: 3);
    expect(quote.total, 85.00);
  });

  test('Miles past the included 5 are charged per mile', () {
    const quote = Quote(vehicle: VehicleTier.haul, items: [boxes], miles: 8);
    expect(quote.distanceFee, 6.00);
    expect(quote.total, 45 + 2.50 + 6 + 10);
  });

  test('pointAlong walks the route by distance', () {
    const a = LatLng(48.77, -123.71), b = LatLng(48.77, -123.69);
    const c = LatLng(48.79, -123.69);
    final path = [a, b, c];
    expect(pointAlong(path, 0), a);
    expect(pointAlong(path, 1), c);
    // The first leg is shorter than the second, so halfway is past b.
    final mid = pointAlong(path, 0.5);
    expect(mid.longitude, closeTo(-123.69, 1e-6));
    expect(mid.latitude, greaterThan(48.77));
    expect(routeMiles(a, b), closeTo(1.2, 0.2));
  });

  test('Driver keeps 75% of the fare plus 100% of the tip', () {
    const quote = Quote(vehicle: VehicleTier.haul, items: [sofa], miles: 4.2);
    const payout = DriverPayout(quote, tip: 10);
    expect(payout.fare, 52.50); // $62.50 minus the $10 safety fee
    expect(payout.commission, 13.13);
    expect(payout.total, closeTo(49.37, 0.001));
  });

  test('Muscle is helpers x hours x \$35 plus the safety fee', () {
    const quote = Quote(
      vehicle: VehicleTier.muscle,
      items: [sofa],
      miles: 12,
      helpers: 2,
      hours: 2,
    );
    expect(quote.basePrice, 140);
    expect(quote.itemsFee, 0);
    expect(quote.distanceFee, 0);
    expect(quote.total, 150);
  });
}
