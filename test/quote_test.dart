import 'package:flutter_test/flutter_test.dart';
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
    final path = roadRoute(const Offset(0, 0), const Offset(100, 100));
    expect(pointAlong(path, 0), const Offset(0, 0));
    expect(pointAlong(path, 0.5), const Offset(100, 0));
    expect(pointAlong(path, 1), const Offset(100, 100));
  });
}
