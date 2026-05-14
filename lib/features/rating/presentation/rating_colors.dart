import 'package:flutter/material.dart';

import '../domain/cleanliness_rating.dart';

extension RatingColors on CleanlinessRating {
  Color get color {
    return switch (this) {
      CleanlinessRating.green => const Color(0xFF2E7D32),
      CleanlinessRating.orange => const Color(0xFFF57C00),
      CleanlinessRating.red => const Color(0xFFC62828),
    };
  }
}
