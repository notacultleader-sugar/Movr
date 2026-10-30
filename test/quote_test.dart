import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:movr/data/mock_data.dart';
import 'package:movr/models/move.dart';

void main() {
  test('A sofa costs \$75: \$30 truck + \$35 large item + \$10 safety fee', () {
    const quote = Quote(vehicle: VehicleTier.truck, items: [sofa], miles: 4.2);
    expect(quote.total, 75.00);
  });

  test('Each item adds its size price', () {
    const quote = Quote(
      vehicle: VehicleTier.truck,
      items: [boxes, tv, sofa, fridge],
      miles: 3,
    );
    expect(quote.itemsFee, 10 + 20 + 35 + 55);
  });

  test('Miles past the included 5 are charged per mile', () {
    const quote = Quote(vehicle: VehicleTier.truck, items: [boxes], miles: 8);
    expect(quote.distanceFee, 6.00);
    expect(quote.total, 30 + 10 + 6 + 10);
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
    const quote = Quote(vehicle: VehicleTier.truck, items: [sofa], miles: 4.2);
    const payout = DriverPayout(quote, tip: 10);
    expect(payout.fare, 65.00); // $75 minus the $10 safety fee
    expect(payout.commission, 16.25);
    expect(payout.total, closeTo(58.75, 0.001));
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
