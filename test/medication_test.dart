import 'package:flutter_test/flutter_test.dart';
import 'package:healthworker/models/medication.dart';

Medication _med({
  double? mgPerKg,
  Map<String, double> table = const {},
  String unit = 'mg',
  bool ageBased = false,
  String? ageRestrictions,
}) =>
    Medication(
      name: 'Test',
      type: 'test',
      mgPerKg: mgPerKg,
      dosageByWeight: table,
      unit: unit,
      sideEffects: const [],
      contraindications: '',
      ageBased: ageBased,
      ageRestrictions: ageRestrictions,
    );

void main() {
  group('Medication.doseFor — formula path', () {
    test('uses mg/kg formula', () {
      final r = _med(mgPerKg: 15).doseFor(10);
      expect(r.isKnown, true);
      expect(r.amount, 150);
    });

    test('caps at the DRUG-SPECIFIC table max, not a global 1000', () {
      // Ibuprofen-like: 7.5 mg/kg, table max 400.
      final m = _med(
        mgPerKg: 7.5,
        table: const {'5.0': 40, '50.0': 400},
      );
      final r = m.doseFor(70); // 525 raw
      expect(r.amount, 400);
      expect(r.capped, true);
    });

    test('caps even when unit is not exactly "mg"', () {
      // Ferrous-sulfate-like: unit 'mg elemental iron daily', max 60.
      final m = _med(
        mgPerKg: 3,
        table: const {'5.0': 15, '20.0': 60},
        unit: 'mg elemental iron daily',
      );
      final r = m.doseFor(40); // 120 raw — must cap at 60
      expect(r.amount, 60);
      expect(r.capped, true);
    });

    test('falls back to 1000 mg cap only when no table and unit is mg', () {
      final r = _med(mgPerKg: 15).doseFor(80); // 1200 raw
      expect(r.amount, 1000);
      expect(r.capped, true);
    });
  });

  group('Medication.doseFor — table path (floor lookup)', () {
    // Artemether-lumefantrine-like WHO bands.
    final al = _med(table: const {
      '5.0': 20,
      '10.0': 20,
      '15.0': 40,
      '20.0': 40,
      '25.0': 60,
      '30.0': 60,
      '40.0': 80,
      '50.0': 80,
    });

    test('14.9 kg stays in the 1-tablet band (no early band jump)', () {
      final r = al.doseFor(14.9);
      expect(r.amount, 20); // NOT 40
    });

    test('15.0 kg enters the 2-tablet band exactly at the boundary', () {
      expect(al.doseFor(15.0).amount, 40);
    });

    test('24.9 kg stays at 2 tablets', () {
      expect(al.doseFor(24.9).amount, 40);
    });

    test('weight below the table refuses to dose', () {
      final r = al.doseFor(3.5);
      expect(r.isKnown, false);
      expect(r.reason, contains('Below the dosing table'));
    });

    test('zero-dose bucket means not recommended', () {
      final m = _med(
        table: const {'5.0': 0, '10.0': 500},
        ageRestrictions: 'Not under 12 months.',
      );
      final r = m.doseFor(7);
      expect(r.isKnown, false);
      expect(r.reason, contains('Not recommended'));
    });
  });

  group('Medication.doseFor — age-based drugs', () {
    test('never returns a weight-computed dose', () {
      final m = _med(
        table: const {'5.0': 50000, '10.0': 100000},
        ageBased: true,
        ageRestrictions: '50,000 IU under 6 months.',
        unit: 'IU',
      );
      final r = m.doseFor(9); // heavy young infant — must NOT get 100k
      expect(r.isKnown, false);
      expect(r.reason, contains('AGE'));
    });
  });

  group('Medication.fromJson', () {
    test('parses full record including ageBased', () {
      final m = Medication.fromJson({
        'name': 'Vitamin A',
        'type': 'supplement',
        'dosageByWeight': {'5.0': 50000},
        'unit': 'IU',
        'sideEffects': [],
        'contraindications': '',
        'ageBased': true,
      });
      expect(m.ageBased, true);
    });

    test('ageBased defaults to false', () {
      final m = Medication.fromJson({
        'name': 'Amoxicillin',
        'type': 'antibiotic',
        'dosageByWeight': {'5.0': 200},
        'unit': 'mg',
        'sideEffects': [],
        'contraindications': '',
      });
      expect(m.ageBased, false);
    });
  });
}
