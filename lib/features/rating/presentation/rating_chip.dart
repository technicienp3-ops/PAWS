import 'package:flutter/material.dart';

import '../domain/cleanliness_rating.dart';
import 'rating_colors.dart';

class RatingChip extends StatelessWidget {
  const RatingChip({super.key, required this.rating});

  final CleanlinessRating rating;

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: rating.color.withOpacity(0.12),
      side: BorderSide(color: rating.color),
      label: Text(
        rating.label,
        style: TextStyle(
          color: rating.color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
