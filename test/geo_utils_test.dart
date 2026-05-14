import 'package:flutter_test/flutter_test.dart';
import 'package:paws_toilet_aire/features/map/domain/geo_utils.dart';

void main() {
  test('distanceInKm returns an expected Paris to Lyon distance range', () {
    final distance = distanceInKm(
      startLatitude: 48.8566,
      startLongitude: 2.3522,
      endLatitude: 45.7640,
      endLongitude: 4.8357,
    );

    expect(distance, greaterThan(380));
    expect(distance, lessThan(410));
  });

  test('boundingBoxForRadius creates a 50 km search area by default', () {
    final box = boundingBoxForRadius(latitude: 48.8566, longitude: 2.3522);

    expect(box.minLatitude, lessThan(48.8566));
    expect(box.maxLatitude, greaterThan(48.8566));
    expect(box.minLongitude, lessThan(2.3522));
    expect(box.maxLongitude, greaterThan(2.3522));
  });
}
