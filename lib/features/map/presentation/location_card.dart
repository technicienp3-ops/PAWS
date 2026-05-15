import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../rating/presentation/rating_chip.dart';
import '../../rating/presentation/rating_sheet.dart';
import '../domain/aire_location.dart';

class LocationCard extends StatelessWidget {
  const LocationCard({
    super.key,
    required this.location,
    required this.onSelected,
    required this.onRatingSubmitted,
  });

  final AireLocation location;
  final VoidCallback onSelected;
  final VoidCallback onRatingSubmitted;

  Future<void> _openNavigation() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openRatingSheet(BuildContext context) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RatingSheet(location: location),
    );

    if (saved == true) {
      onRatingSubmitted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: location.category.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      location.category.icon,
                      color: location.category.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${location.type} • ${location.distanceKm?.toStringAsFixed(2) ?? '?'} km',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  RatingChip(rating: location.rating),
                ],
              ),
              const SizedBox(height: 12),
              Text('${location.ratingCount} avis de propreté'),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _openNavigation,
                    icon: const Icon(Icons.near_me),
                    label: const Text('Itinéraire'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _openRatingSheet(context),
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Noter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
