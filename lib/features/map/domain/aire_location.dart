import '../../rating/domain/cleanliness_rating.dart';

class AireLocation {
  const AireLocation({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.ratingCount,
    this.photoUrl,
    this.distanceKm,
  });

  final String id;
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  final CleanlinessRating rating;
  final int ratingCount;
  final String? photoUrl;
  final double? distanceKm;

  AireLocation copyWithDistance(double distanceKm) {
    return AireLocation(
      id: id,
      name: name,
      type: type,
      latitude: latitude,
      longitude: longitude,
      rating: rating,
      ratingCount: ratingCount,
      photoUrl: photoUrl,
      distanceKm: distanceKm,
    );
  }
}
