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
  final _commentController = TextEditingController();
  CleanlinessRating _rating = CleanlinessRating.green;
  bool _isSaving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    await _repository.submitRating(
      locationId: widget.location.id,
      rating: _rating,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Noter ${widget.location.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<CleanlinessRating>(
              segments: CleanlinessRating.values
                  .map(
                    (rating) => ButtonSegment(
                      value: rating,
                      label: Text(rating.label),
                      icon: Icon(Icons.circle, color: rating.color),
                    ),
                  )
                  .toList(),
              selected: {_rating},
              onSelectionChanged: _isSaving
                  ? null
                  : (selection) => setState(() => _rating = selection.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              enabled: !_isSaving,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Commentaire optionnel',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Envoyer la note'),
            ),
          ],
        ),
      ),
    );
  }
}
