import 'package:flutter_test/flutter_test.dart';
import 'package:paws_toilet_aire/features/map/data/location_repository.dart';
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

  test('boundingBoxForRadius creates a 100 km search area by default', () {
    final box = boundingBoxForRadius(latitude: 48.8566, longitude: 2.3522);

    expect(box.minLatitude, lessThan(48.8566));
    expect(box.maxLatitude, greaterThan(48.8566));
    expect(box.minLongitude, lessThan(2.3522));
    expect(box.maxLongitude, greaterThan(2.3522));
  });

  test('Overpass query includes all PAWS discovery tags and 100 km radius', () {
    final query = LocationRepository().buildOverpassQuery(
      latitude: 45.61,
      longitude: 5.21,
      radiusMeters: 100000,
    );

    expect(query, contains('[out:json][timeout:45];'));
    expect(
      query,
      contains(
        'node[\"amenity\"=\"toilets\"](around:100000,45.61,5.21);',
      ),
    );
    expect(query, contains('way[\"amenity\"=\"public_bath\"]'));
    expect(query, contains('relation[\"toilets:public\"=\"yes\"]'));
    expect(query, contains('node[\"highway\"=\"rest_area\"]'));
    expect(query, contains('way[\"amenity\"=\"sanitary_dump_station\"]'));
    expect(query, isNot(contains('leisure')));
    expect(query, contains('out center tags;'));
  });

  test('Overpass URI exposes the encoded query for debugging', () {
    final repository = LocationRepository();
    final query = repository.buildOverpassQuery(
      latitude: 45.61,
      longitude: 5.21,
      radiusMeters: 100000,
    );
    final uri = repository.buildOverpassUri(query);

    expect(
      uri.toString(),
      startsWith('https://overpass-api.de/api/interpreter?data='),
    );
    expect(uri.queryParameters['data'], query);
  });
}
