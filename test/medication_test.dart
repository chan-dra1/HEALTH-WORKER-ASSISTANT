import 'package:flutter_test/flutter_test.dart';
import 'package:healthworker/models/medication.dart';

void main() {
  group('Medication.doseFor', () {
    test('uses mg/kg formula when available', () {
      final m = Medication(
        name: 'Paracetamol',
        type: 'analgesic',
        mgPerKg: 15,
        dosageByWeight: const {},
        unit: 'mg',
        sideEffects: const [],
        contraindications: '',
      );
      final r = m.doseFor(10);
      expect(r.isKnown, true);
      expect(r.amount, 150);
      expect(r.unit, 'mg');
      expect(r.capped, false);
    });

    test('caps at adult single-dose ceiling when formula would exceed', () {
      final m = Medication(
        name: 'Paracetamol',
        type: 'analgesic',
        mgPerKg: 15,
        dosageByWeight: const {},
        unit: 'mg',
        sideEffects: const [],
        contraindications: '',
      );
      final r = m.doseFor(80); // 15 * 80 = 1200, should cap to 1000
      expect(r.amount, 1000);
      expect(r.capped, true);
    });

    test('falls back to table when no mg/kg', () {
      final m = Medication(
        name: 'AL',
        type: 'antimalarial',
        dosageByWeight: const {'10.0': 20, '20.0': 40, '30.0': 60},
        unit: 'mg',
        sideEffects: const [],
        contraindications: '',
      );
      final r = m.doseFor(20.4);
      expect(r.isKnown, true);
      expect(r.amount, 40); // closest bucket
    });

    test('returns unknown when nothing to compute', () {
      final m = Medication(
        name: 'Empty',
        type: '',
        dosageByWeight: const {},
        unit: 'mg',
        sideEffects: const [],
        contraindications: '',
      );
      final r = m.doseFor(10);
      expect(r.isKnown, false);
    });
  });

  group('Medication.fromJson', () {
    test('parses full record from drug_reference.json shape', () {
      final m = Medication.fromJson({
        'name': 'Amoxicillin',
        'type': 'antibiotic',
        'indications': ['pneumonia'],
        'mgPerKg': 25,
        'dosageByWeight': {'5.0': 125, '10.0': 250},
        'unit': 'mg',
        'frequency': 'twice daily',
        'maxDailyDose': '90 mg/kg/day',
        'route': 'oral',
        'sideEffects': ['rash'],
        'contraindications': 'penicillin allergy',
        'sources': ['WHO Pocket Book'],
      });
      expect(m.name, 'Amoxicillin');
      expect(m.mgPerKg, 25);
      expect(m.dosageByWeight['10.0'], 250);
      expect(m.indications, ['pneumonia']);
      expect(m.sources, ['WHO Pocket Book']);
    });
  });
}
