import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../rating/presentation/rating_colors.dart';
import '../data/location_repository.dart';
import '../domain/geo_utils.dart';
import 'location_card.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _repository = LocationRepository();
  late Future<_NearbyState> _nearbyFuture;

  @override
  void initState() {
    super.initState();
    _nearbyFuture = _loadNearby();
  }

  Future<_NearbyState> _loadNearby() async {
    final position = await _repository.resolveCurrentPosition();
    final locations = await _repository.fetchNearbyLocations(position);
    return _NearbyState(position: position, locations: locations);
  }

  void _refresh() {
    setState(() => _nearbyFuture = _loadNearby());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PAWS'),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_NearbyState>(
        future: _nearbyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error, onRetry: _refresh);
          }
          final nearby = snapshot.requireData;
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _HeroMap(state: nearby)),
                if (nearby.locations.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  SliverList.builder(
                    itemCount: nearby.locations.length,
                    itemBuilder: (context, index) => LocationCard(
                      location: nearby.locations[index],
                      onRatingSubmitted: _refresh,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroMap extends StatelessWidget {
  const _HeroMap({required this.state});

  final _NearbyState state;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(state.position.latitude, state.position.longitude);
    final tileUrl = 'https://tile.' 'openstreetmap.' 'org/{z}/{x}/{y}.png';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFE8F5E9)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset('assets/images/paws_logo.svg', height: 72),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Toilet & Aire', style: Theme.of(context).textTheme.headlineSmall),
                    Text('Sanitaires et aires à moins de ${nearbyRadiusKm.toStringAsFixed(0)} km'),
                    Text(
                      'Position : ${state.position.latitude.toStringAsFixed(4)}, ${state.position.longitude.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 230,
              width: double.infinity,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(urlTemplate: tileUrl),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 44,
                        height: 44,
                        child: const Icon(Icons.my_location, color: Color(0xFF1565C0), size: 38),
                      ),
                      for (final location in state.locations.take(30))
                        Marker(
                          point: LatLng(location.latitude, location.longitude),
                          width: 40,
                          height: 40,
                          child: Tooltip(
                            message: location.name,
                            child: Icon(Icons.location_on, color: location.rating.color, size: 34),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Aucun sanitaire ou aire référencé dans un rayon de 50 km.'),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 48),
            const SizedBox(height: 12),
            Text(
              'Impossible de charger les aires proches. Activez la localisation et vérifiez Firebase.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class _NearbyState {
  const _NearbyState({required this.position, required this.locations});

  final Position position;
  final List<dynamic> locations;
}
