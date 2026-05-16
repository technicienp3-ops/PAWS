import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../rating/domain/cleanliness_rating.dart';
import '../domain/aire_location.dart';
import '../domain/geo_utils.dart';

class LocationRepository {
  LocationRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

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
    final query = _buildQuery(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusMeters: (nearbyRadiusKm * 1000).round(),
    );

    final uri = Uri.https(
      'overpass-api.de',
      '/api/interpreter',
      {'data': query},
    );

    final response = await _httpClient
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 60));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erreur OpenStreetMap ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = decoded['elements'] as List<dynamic>? ?? [];

    final locations = elements
        .map((element) => _fromElement(element as Map<String, dynamic>))
        .whereType<AireLocation>()
        .map((location) {
      final distance = distanceInKm(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        endLatitude: location.latitude,
        endLongitude: location.longitude,
      );
      return location.copyWithDistance(distance);
    }).toList();

    locations.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    return locations;
  }

  String _buildQuery({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) {
    final filters = [
      '"amenity"="toilets"',
      '"shop"="convenience"',
      '"amenity"="fuel"',
      '"amenity"="charging_station"',
    ];
    final types = ['node', 'way', 'relation'];

    final lines = <String>[
      '[out:json][timeout:45];',
      '(',
      for (final type in types)
        for (final filter in filters)
          '  $type[$filter](around:$radiusMeters,$latitude,$longitude);',
      ');',
      'out center tags;',
    ];

    return lines.join('\n');
  }

  AireLocation? _fromElement(Map<String, dynamic> element) {
    final tags = element['tags'] as Map<String, dynamic>? ?? {};
    final center = element['center'] as Map<String, dynamic>?;
    final latitude = (element['lat'] as num?) ?? (center?['lat'] as num?);
    final longitude = (element['lon'] as num?) ?? (center?['lon'] as num?);

    if (latitude == null || longitude == null) return null;

    final category = _categoryFromTags(tags);
    final type = _labelForCategory(category);
    final osmType = element['type'] as String? ?? 'element';
    final osmId = element['id']?.toString() ?? '${latitude}_$longitude';

    return AireLocation(
      id: 'osm_${osmType}_$osmId',
      name: tags['name'] as String? ?? type,
      type: type,
      category: category,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      rating: CleanlinessRating.orange,
      ratingCount: 0,
    );
  }

  LocationCategory _categoryFromTags(Map<String, dynamic> tags) {
    if (tags['amenity'] == 'toilets') return LocationCategory.toilets;
    if (tags['shop'] == 'convenience') return LocationCategory.shop;
    if (tags['amenity'] == 'fuel') return LocationCategory.fuel;
    if (tags['amenity'] == 'charging_station') {
      return LocationCategory.charging;
    }
    return LocationCategory.other;
  }

  String _labelForCategory(LocationCategory category) {
    return switch (category) {
      LocationCategory.toilets => 'Toilettes',
      LocationCategory.shop => 'Boutique',
      LocationCategory.fuel => 'Station-service',
      LocationCategory.charging => 'Recharge électrique',
      LocationCategory.other => 'Lieu utile',
    };
  }
}
