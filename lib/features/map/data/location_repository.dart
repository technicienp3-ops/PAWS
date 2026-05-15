import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../rating/domain/cleanliness_rating.dart';
import '../domain/aire_location.dart';
import '../domain/geo_utils.dart';

const _overpassEndpoint = 'https://overpass-api.de/api/interpreter';
const _overpassTimeout = Duration(seconds: 60);
const _overpassQueryTimeoutSeconds = 45;

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
    final locations = await _fetchOverpassLocations(position);

    return locations.map((location) {
      final distance = distanceInKm(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        endLatitude: location.latitude,
        endLongitude: location.longitude,
      );
      return location.copyWithDistance(distance);
    }).toList()
      ..sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
  }

  Future<List<AireLocation>> _fetchOverpassLocations(Position position) async {
    final radiusMeters = (nearbyRadiusKm * 1000).round();
    final query = buildOverpassQuery(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusMeters: radiusMeters,
    );

    final overpassUri = buildOverpassUri(query);
    // ignore: avoid_print
    print('Overpass URL: $overpassUri');

    http.Response response;
    try {
      response = await _httpClient
          .get(
            overpassUri,
            headers: const {'Accept': 'application/json'},
          )
          .timeout(_overpassTimeout);
    } on TimeoutException catch (error) {
      throw OverpassSearchException(
        'Timeout Overpass après ${_overpassTimeout.inSeconds}s: $error',
      );
    } on http.ClientException catch (error) {
      throw OverpassSearchException('Erreur HTTP Overpass: $error');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final bodyPreview = response.body.length > 500
          ? '${response.body.substring(0, 500)}…'
          : response.body;
      throw OverpassSearchException(
        'Overpass a répondu ${response.statusCode}: $bodyPreview',
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = json['elements'] as List<dynamic>? ?? [];
      return elements
          .map(
            (element) => _fromOverpassElement(
              element as Map<String, dynamic>,
            ),
          )
          .whereType<AireLocation>()
          .toList();
    } on FormatException catch (error) {
      throw OverpassSearchException('Réponse JSON Overpass invalide: $error');
    } on TypeError catch (error) {
      throw OverpassSearchException('Format Overpass inattendu: $error');
    }
  }

  String buildOverpassQuery({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) {
    final filters = <String>[
      '"amenity"="toilets"',
      '"shop"="convenience"',
      '"amenity"="fuel"',
      '"amenity"="charging_station"',
    ];
    final elementTypes = ['node', 'way', 'relation'];

    final lines = <String>[
      '[out:json][timeout:$_overpassQueryTimeoutSeconds];',
      '(',
      for (final type in elementTypes)
        for (final filter in filters)
          '  $type[$filter](around:$radiusMeters,$latitude,$longitude);',
      ');',
      'out center tags;',
    ];

    return lines.join('\n');
  }

  Uri buildOverpassUri(String query) {
    return Uri.parse(_overpassEndpoint).replace(
      queryParameters: {'data': query},
    );
  }

  AireLocation? _fromOverpassElement(Map<String, dynamic> element) {
    final tags = (element['tags'] as Map<String, dynamic>?) ?? {};
    final center = element['center'] as Map<String, dynamic>?;
    final latitude = (element['lat'] as num?) ?? (center?['lat'] as num?);
    final longitude = (element['lon'] as num?) ?? (center?['lon'] as num?);

    if (latitude == null || longitude == null) {
      return null;
    }

    final osmType = element['type'] as String? ?? 'element';
    final osmId = element['id'] as num?;
    final category = _locationCategory(tags);
    final kind = _locationKind(category);
    return AireLocation(
      id: 'osm_${osmType}_${osmId ?? '${latitude}_$longitude'}',
      name: tags['name'] as String? ?? kind,
      type: kind,
      category: category,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      rating: CleanlinessRating.orange,
      ratingCount: 0,
    );
  }

  LocationCategory _locationCategory(Map<String, dynamic> tags) {
    if (tags['amenity'] == 'toilets') return LocationCategory.toilets;
    if (tags['shop'] == 'convenience') return LocationCategory.shop;
    if (tags['amenity'] == 'fuel') return LocationCategory.fuel;
    if (tags['amenity'] == 'charging_station') {
      return LocationCategory.charging;
    }
    return LocationCategory.other;
  }

  String _locationKind(LocationCategory category) {
    return switch (category) {
      LocationCategory.toilets => 'Toilettes',
      LocationCategory.shop => 'Boutique',
      LocationCategory.fuel => 'Station-service',
      LocationCategory.charging => 'Recharge électrique',
      LocationCategory.other => 'Lieu utile',
    };
  }
}

class OverpassSearchException implements Exception {
  const OverpassSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}
