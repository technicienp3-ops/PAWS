import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';

import '../data/location_repository.dart';
import '../domain/aire_location.dart';
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
  _LocationFilter _selectedFilter = _LocationFilter.all;
  AireLocation? _selectedLocation;

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
    setState(() {
      _selectedLocation = null;
      _nearbyFuture = _loadNearby();
    });
  }

  void _selectLocation(AireLocation location) {
    setState(() => _selectedLocation = location);
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
          final filteredLocations = _selectedFilter.apply(nearby.locations);
          final selectedLocation = _selectedLocation;

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _FilterBar(
                        selectedFilter: _selectedFilter,
                        onFilterChanged: (filter) {
                          setState(() {
                            _selectedFilter = filter;
                            _selectedLocation = null;
                          });
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _HeroMap(
                        state: nearby,
                        locations: filteredLocations,
                        onLocationSelected: _selectLocation,
                      ),
                    ),
                    if (filteredLocations.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(filter: _selectedFilter),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.only(
                          bottom: selectedLocation == null ? 20 : 190,
                        ),
                        sliver: SliverList.builder(
                          itemCount: filteredLocations.length,
                          itemBuilder: (context, index) => LocationCard(
                            location: filteredLocations[index],
                            onSelected: () =>
                                _selectLocation(filteredLocations[index]),
                            onRatingSubmitted: _refresh,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _LocationDetailsPanel(
                location: selectedLocation,
                onClose: () => setState(() => _selectedLocation = null),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final _LocationFilter selectedFilter;
  final ValueChanged<_LocationFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        scrollDirection: Axis.horizontal,
        itemCount: _LocationFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = _LocationFilter.values[index];
          final selected = filter == selectedFilter;
          return ChoiceChip(
            selected: selected,
            label: Text(filter.label),
            avatar: Icon(filter.icon, size: 18),
            onSelected: (_) => onFilterChanged(filter),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : null,
            ),
            selectedColor: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            elevation: selected ? 2 : 0,
            pressElevation: 1,
          );
        },
      ),
    );
  }
}

class _HeroMap extends StatelessWidget {
  const _HeroMap({
    required this.state,
    required this.locations,
    required this.onLocationSelected,
  });

  final _NearbyState state;
  final List<AireLocation> locations;
  final ValueChanged<AireLocation> onLocationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFE8F5E9)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1565C0),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
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
                    Text(
                      'Toilet & Aire',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '${locations.length} lieux utiles à moins de '
                      '${nearbyRadiusKm.toStringAsFixed(0)} km',
                    ),
                    Text(
                      'Position : '
                      '${state.position.latitude.toStringAsFixed(4)}, '
                      '${state.position.longitude.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF90CAF9)),
            ),
            child: Stack(
              children: [
                const Positioned.fill(child: _MapGrid()),
                const Center(
                  child: Icon(
                    Icons.my_location,
                    color: Color(0xFF1565C0),
                    size: 36,
                  ),
                ),
                for (final location in locations.take(18))
                  _LocationDot(
                    location: location,
                    onTap: () => onLocationSelected(location),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGrid extends StatelessWidget {
  const _MapGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBBDEFB)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final dx = size.width * i / 5;
      final dy = size.height * i / 5;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LocationDot extends StatelessWidget {
  const _LocationDot({required this.location, required this.onTap});

  final AireLocation location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final distance =
        (location.distanceKm ?? nearbyRadiusKm)
            .clamp(0, nearbyRadiusKm)
            .toDouble();
    final angle = (location.latitude + location.longitude).abs() % 6.28318;
    final radiusFactor = distance / nearbyRadiusKm;
    return Align(
      alignment: Alignment(
        (radiusFactor * 0.82) * math.cos(angle),
        (radiusFactor * 0.82) * math.sin(angle),
      ),
      child: Tooltip(
        message: location.name,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Icon(
            location.category.icon,
            color: location.category.color,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _LocationDetailsPanel extends StatelessWidget {
  const _LocationDetailsPanel({required this.location, required this.onClose});

  final AireLocation? location;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final location = this.location;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      left: 16,
      right: 16,
      bottom: location == null ? -220 : 18,
      child: IgnorePointer(
        ignoring: location == null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: location == null ? 0 : 1,
          child: location == null
              ? const SizedBox.shrink()
              : Material(
                  elevation: 8,
                  color: Theme.of(context).colorScheme.surface,
                  shadowColor: Colors.black.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: location.category.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                location.category.icon,
                                color: location.category.color,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    location.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  Text(location.type),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: onClose,
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _DetailPill(
                              icon: Icons.route,
                              label: '${location.distanceKm?.toStringAsFixed(2) ?? '?'} km',
                            ),
                            _DetailPill(
                              icon: Icons.place,
                              label:
                                  '${location.latitude.toStringAsFixed(5)}, '
                                  '${location.longitude.toStringAsFixed(5)}',
                            ),
                            _DetailPill(
                              icon: Icons.star,
                              label: '${location.ratingCount} avis',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final _LocationFilter filter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Aucun résultat « ${filter.label} » dans un rayon de '
          '${nearbyRadiusKm.toStringAsFixed(0)} km.',
        ),
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
              'Impossible de charger les lieux proches. '
              'Le détail technique est affiché ci-dessous.',
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
  final List<AireLocation> locations;
}

enum _LocationFilter {
  all('Tous', Icons.apps),
  toilets('Toilettes', Icons.wc),
  shops('Boutiques', Icons.storefront),
  charging('Recharge ⚡', Icons.bolt);

  const _LocationFilter(this.label, this.icon);

  final String label;
  final IconData icon;

  List<AireLocation> apply(List<AireLocation> locations) {
    return switch (this) {
      _LocationFilter.all => locations,
      _LocationFilter.toilets => locations
          .where((location) => location.category == LocationCategory.toilets)
          .toList(),
      _LocationFilter.shops => locations
          .where((location) => location.category == LocationCategory.shop)
          .toList(),
      _LocationFilter.charging => locations
          .where((location) => location.category == LocationCategory.charging)
          .toList(),
    };
  }
}

extension on LocationCategory {
  IconData get icon {
    return switch (this) {
      LocationCategory.toilets => Icons.wc,
      LocationCategory.shop => Icons.storefront,
      LocationCategory.fuel => Icons.local_gas_station,
      LocationCategory.charging => Icons.bolt,
      LocationCategory.other => Icons.place,
    };
  }

  Color get color {
    return switch (this) {
      LocationCategory.toilets => const Color(0xFF1565C0),
      LocationCategory.shop => const Color(0xFF7B1FA2),
      LocationCategory.fuel => const Color(0xFF00897B),
      LocationCategory.charging => const Color(0xFFF9A825),
      LocationCategory.other => const Color(0xFF546E7A),
    };
  }
}
