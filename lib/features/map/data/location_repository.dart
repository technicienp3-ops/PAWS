import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../../rating/domain/cleanliness_rating.dart';
import '../domain/aire_location.dart';
import '../domain/geo_utils.dart';

class LocationRepository {
  LocationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Position> resolveCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw PermissionDeniedException('La géolocalisation est nécessaire.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<List<AireLocation>> fetchNearbyLocations(Position position) async {
    final box = boundingBoxForRadius(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    final snapshot = await _firestore
        .collection('locations')
        .where('latitude', isGreaterThanOrEqualTo: box.minLatitude)
        .where('latitude', isLessThanOrEqualTo: box.maxLatitude)
        .get();

    final locations = snapshot.docs
        .map((doc) => _fromDocument(doc))
        .where((location) =>
            location.longitude >= box.minLongitude &&
            location.longitude <= box.maxLongitude)
        .map((location) {
          final distance = distanceInKm(
            startLatitude: position.latitude,
            startLongitude: position.longitude,
            endLatitude: location.latitude,
            endLongitude: location.longitude,
          );
          return location.copyWithDistance(distance);
        })
        .where(
          (location) =>
              (location.distanceKm ?? double.infinity) <= nearbyRadiusKm,
        )
        .toList()
      ..sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));

    return locations;
  }

  AireLocation _fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return AireLocation(
      id: doc.id,
      name: data['name'] as String? ?? 'Sanitaires sans nom',
      type: data['type'] as String? ?? 'Aire',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      rating: CleanlinessRating.fromScore(data['averageRating'] as num?),
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      photoUrl: data['photoUrl'] as String?,
    );
  }
}
