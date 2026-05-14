import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../rating/presentation/rating_chip.dart';
import '../../rating/presentation/rating_sheet.dart';
import '../domain/aire_location.dart';

class LocationCard extends StatelessWidget {
  const LocationCard({
    super.key,
    required this.location,
    required this.onRatingSubmitted,
  });

  final AireLocation location;
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        '${location.type} • ${location.distanceKm?.toStringAsFixed(1) ?? '?'} km',
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
    );
  }
}
