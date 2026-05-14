import 'dart:math';

const nearbyRadiusKm = 100.0;

class BoundingBox {
  const BoundingBox({
    required this.minLatitude,
    required this.maxLatitude,
    required this.minLongitude,
    required this.maxLongitude,
  });

  final double minLatitude;
  final double maxLatitude;
  final double minLongitude;
  final double maxLongitude;
}

double distanceInKm({
  required double startLatitude,
  required double startLongitude,
  required double endLatitude,
  required double endLongitude,
}) {
  const earthRadiusKm = 6371.0;
  final dLat = _degreesToRadians(endLatitude - startLatitude);
  final dLon = _degreesToRadians(endLongitude - startLongitude);
  final lat1 = _degreesToRadians(startLatitude);
  final lat2 = _degreesToRadians(endLatitude);

  final a = pow(sin(dLat / 2), 2) +
      cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

BoundingBox boundingBoxForRadius({
  required double latitude,
  required double longitude,
  double radiusKm = nearbyRadiusKm,
}) {
  const kmPerLatitudeDegree = 111.32;
  final latitudeDelta = radiusKm / kmPerLatitudeDegree;
  final latitudeCosine =
      cos(_degreesToRadians(latitude)).abs().clamp(0.01, 1).toDouble();
  final longitudeDelta = radiusKm / (kmPerLatitudeDegree * latitudeCosine);

  return BoundingBox(
    minLatitude: latitude - latitudeDelta,
    maxLatitude: latitude + latitudeDelta,
    minLongitude: longitude - longitudeDelta,
    maxLongitude: longitude + longitudeDelta,
  );
}

double _degreesToRadians(double degrees) => degrees * pi / 180;
