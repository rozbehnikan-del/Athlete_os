/// Prescription completion only; this is not a measure of athletic ability.
class CompletionGrade {
  CompletionGrade({required int completedSets, required int totalSets})
    : percentage = totalSets <= 0
          ? null
          : completedSets.clamp(0, totalSets) / totalSets * 100;

  final double? percentage;
  String? get grade {
    final p = percentage;
    if (p == null) return null;
    if (p >= 90) return 'A';
    if (p >= 75) return 'B';
    if (p >= 50) return 'C';
    return 'D';
  }

  String get label => percentage == null
      ? 'Completion Grade unavailable'
      : 'Completion Grade $grade • ${percentage!.toStringAsFixed(1)}%';
}
