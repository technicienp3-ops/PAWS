import 'package:flutter/material.dart';

import '../../map/domain/aire_location.dart';
import '../data/rating_repository.dart';
import '../domain/cleanliness_rating.dart';
import 'rating_colors.dart';

class RatingSheet extends StatefulWidget {
  const RatingSheet({super.key, required this.location});

  final AireLocation location;

  @override
  State<RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<RatingSheet> {
  final _repository = RatingRepository();
  CleanlinessRating? _savingRating;

  Future<void> _submit(CleanlinessRating rating) async {
    if (_savingRating != null) return;

    setState(() => _savingRating = rating);

    try {
      await _repository.submitRating(
        locationId: widget.location.id,
        rating: rating,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _savingRating = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’envoyer la note : $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + 20;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: bottomPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Comment sont les toilettes ?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.location.name,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            for (final rating in CleanlinessRating.values) ...[
              _RatingOptionCard(
                rating: rating,
                isSaving: _savingRating == rating,
                isDisabled: _savingRating != null,
                onTap: () => _submit(rating),
              ),
              if (rating != CleanlinessRating.values.last)
                const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _RatingOptionCard extends StatelessWidget {
  const _RatingOptionCard({
    required this.rating,
    required this.isSaving,
    required this.isDisabled,
    required this.onTap,
  });

  final CleanlinessRating rating;
  final bool isSaving;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = rating.color;
    final foregroundColor = isDisabled && !isSaving
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : color;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isDisabled && !isSaving ? 0.48 : 1,
      child: Material(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: color.withOpacity(0.36), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.84),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: isSaving
                      ? Padding(
                          padding: const EdgeInsets.all(22),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: color,
                          ),
                        )
                      : Icon(rating.icon, color: foregroundColor, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.label,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: foregroundColor,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rating.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.touch_app, color: foregroundColor, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on CleanlinessRating {
  IconData get icon {
    return switch (this) {
      CleanlinessRating.green => Icons.auto_awesome,
      CleanlinessRating.orange => Icons.sentiment_neutral,
      CleanlinessRating.red => Icons.sentiment_very_dissatisfied,
    };
  }
}
