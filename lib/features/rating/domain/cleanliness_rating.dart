enum CleanlinessRating {
  green('Propre', 'Sanitaires propres et agréables', 3),
  orange('Sale', 'Propreté moyenne ou à améliorer', 2),
  red('Dégueulasse', 'Très sale ou à éviter', 1);

  const CleanlinessRating(this.label, this.description, this.score);

  final String label;
  final String description;
  final int score;

  static CleanlinessRating fromScore(num? score) {
    if (score == null) return CleanlinessRating.orange;
    if (score >= 2.5) return CleanlinessRating.green;
    if (score >= 1.5) return CleanlinessRating.orange;
    return CleanlinessRating.red;
  }
}
