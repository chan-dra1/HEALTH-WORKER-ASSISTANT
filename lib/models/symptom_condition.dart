class SymptomCondition {
  final String name;
  final List<String> symptoms;
  final String severity; // 'mild', 'moderate', 'severe'
  final String ageGroup; // 'infant', 'child', 'older-child', 'adult', 'all'
  final String treatment;
  final bool referralNeeded;
  final String? referralCriteria;
  final List<String> medications;
  final List<String> sources;

  SymptomCondition({
    required this.name,
    required this.symptoms,
    required this.severity,
    required this.ageGroup,
    required this.treatment,
    required this.referralNeeded,
    this.referralCriteria,
    required this.medications,
    required this.sources,
  });

  factory SymptomCondition.fromJson(Map<String, dynamic> json) =>
      SymptomCondition(
        name: json['name'] as String,
        symptoms: List<String>.from(json['symptoms'] as List),
        severity: json['severity'] as String? ?? 'moderate',
        ageGroup: json['ageGroup'] as String? ?? 'all',
        treatment: json['treatment'] as String? ?? '',
        referralNeeded: json['referralNeeded'] as bool? ?? false,
        referralCriteria: json['referralCriteria'] as String?,
        medications: List<String>.from(
            (json['medications'] as List?) ?? const []),
        sources:
            List<String>.from((json['sources'] as List?) ?? const []),
      );
}

class ConditionMatch {
  final SymptomCondition condition;
  final int matchedCount;
  final int totalSymptoms;

  ConditionMatch({
    required this.condition,
    required this.matchedCount,
    required this.totalSymptoms,
  });

  // Match score is the fraction of the condition's symptoms the user
  // reported. We do NOT divide by the user's selected count — that would
  // unfairly penalize conditions with many possible symptoms.
  double get matchPercent =>
      totalSymptoms == 0 ? 0 : matchedCount / totalSymptoms;
}
