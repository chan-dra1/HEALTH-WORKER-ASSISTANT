class Medication {
  final String name;
  final String type; // 'antibiotic', 'painkiller', 'antimalarial'
  final Map<String, double> dosageByWeight; // weight kg -> dose mg
  final String unit;
  final List<String> sideEffects;
  final String contraindications;

  Medication({
    required this.name,
    required this.type,
    required this.dosageByWeight,
    required this.unit,
    required this.sideEffects,
    required this.contraindications,
  });

  String? getDosage(double weightKg) {
    final exact = dosageByWeight[weightKg.toStringAsFixed(1)];
    if (exact != null) {
      return '${exact.toStringAsFixed(0)}$unit';
    }

    double? closestWeight;
    double minDiff = double.infinity;
    dosageByWeight.forEach((weight, _) {
      final diff = (double.parse(weight) - weightKg).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestWeight = double.parse(weight);
      }
    });

    if (closestWeight != null) {
      final dose = dosageByWeight[closestWeight!.toStringAsFixed(1)];
      return '$dose$unit (approx)';
    }
    return null;
  }
}
