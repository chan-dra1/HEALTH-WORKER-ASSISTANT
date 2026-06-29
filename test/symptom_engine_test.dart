import 'package:flutter_test/flutter_test.dart';
import 'package:healthworker/models/symptom_condition.dart';

void main() {
  group('ConditionMatch', () {
    test('match% is matchedCount / totalSymptoms', () {
      final m = ConditionMatch(
        condition: _malaria(),
        matchedCount: 3,
        totalSymptoms: 5,
      );
      expect(m.matchPercent, closeTo(0.6, 1e-9));
    });

    test('match% is 0 when no symptoms', () {
      final m = ConditionMatch(
        condition: _malaria(),
        matchedCount: 0,
        totalSymptoms: 0,
      );
      expect(m.matchPercent, 0);
    });
  });

  group('SymptomCondition.fromJson', () {
    test('parses minimal fields with defaults', () {
      final c = SymptomCondition.fromJson({
        'name': 'Test',
        'symptoms': ['a', 'b'],
      });
      expect(c.name, 'Test');
      expect(c.symptoms, ['a', 'b']);
      expect(c.severity, 'moderate');
      expect(c.ageGroup, 'all');
      expect(c.referralNeeded, false);
      expect(c.medications, isEmpty);
      expect(c.sources, isEmpty);
    });

    test('parses severe condition with referral', () {
      final c = SymptomCondition.fromJson({
        'name': 'Severe malaria',
        'symptoms': ['fever', 'convulsions', 'lethargy'],
        'severity': 'severe',
        'ageGroup': 'child',
        'treatment': 'Refer urgently.',
        'referralNeeded': true,
        'referralCriteria': 'Any danger sign',
        'medications': ['artesunate'],
        'sources': ['WHO IMCI'],
      });
      expect(c.severity, 'severe');
      expect(c.referralNeeded, true);
      expect(c.referralCriteria, 'Any danger sign');
      expect(c.medications, ['artesunate']);
    });
  });
}

SymptomCondition _malaria() => SymptomCondition(
      name: 'Malaria',
      symptoms: const ['fever', 'headache', 'chills', 'sweating', 'fatigue'],
      severity: 'moderate',
      ageGroup: 'all',
      treatment: 'AL per WHO',
      referralNeeded: false,
      medications: const ['artemether-lumefantrine'],
      sources: const ['WHO IMCI'],
    );
