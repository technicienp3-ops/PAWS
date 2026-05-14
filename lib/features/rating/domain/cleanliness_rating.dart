enum CleanlinessRating {
  green('Vert', 'Propre', 3),
  orange('Orange', 'Acceptable', 2),
  red('Rouge', 'À éviter', 1);

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
