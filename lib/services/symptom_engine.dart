import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/symptom_condition.dart';

class SymptomEngine {
  static final SymptomEngine _instance = SymptomEngine._internal();
  factory SymptomEngine() => _instance;
  SymptomEngine._internal();

  List<SymptomCondition>? _conditions;
  String _disclaimer = '';
  String _version = '';

  Future<void> load() async {
    if (_conditions != null) return;
    final raw =
        await rootBundle.loadString('assets/data/symptom_database.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _version = json['version'] as String? ?? '0.0.0';
    _disclaimer = json['disclaimer'] as String? ?? '';
    final list = json['conditions'] as List;
    _conditions =
        list.map((c) => SymptomCondition.fromJson(c as Map<String, dynamic>))
            .toList();
  }

  List<SymptomCondition> get conditions => _conditions ?? const [];
  String get disclaimer => _disclaimer;
  String get version => _version;

  // All unique symptoms across the database, sorted, for the picker UI.
  List<String> get allSymptoms {
    final set = <String>{};
    for (final c in conditions) {
      set.addAll(c.symptoms);
    }
    final list = set.toList()..sort();
    return list;
  }

  // Rank conditions by how many of their symptoms match what the user
  // selected. Returns matches with at least one symptom hit, sorted by
  // match% desc, then by severity (severe first — never bury a referral).
  List<ConditionMatch> match(Set<String> selectedSymptoms) {
    if (selectedSymptoms.isEmpty) return const [];

    final matches = <ConditionMatch>[];
    for (final c in conditions) {
      final hits = c.symptoms.where(selectedSymptoms.contains).length;
      if (hits == 0) continue;
      matches.add(ConditionMatch(
        condition: c,
        matchedCount: hits,
        totalSymptoms: c.symptoms.length,
      ));
    }

    matches.sort((a, b) {
      final pct = b.matchPercent.compareTo(a.matchPercent);
      if (pct != 0) return pct;
      return _severityRank(b.condition.severity)
          .compareTo(_severityRank(a.condition.severity));
    });
    return matches;
  }

  int _severityRank(String s) {
    switch (s) {
      case 'severe':
        return 3;
      case 'moderate':
        return 2;
      case 'mild':
        return 1;
      default:
        return 0;
    }
  }
}
