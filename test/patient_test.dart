import 'package:flutter_test/flutter_test.dart';
import 'package:healthworker/models/patient.dart';

void main() {
  group('Patient', () {
    test('computes age from date of birth', () {
      final now = DateTime.now();
      final dob = DateTime(now.year - 30, now.month, now.day);
      final p = _make(dob: dob);
      expect(p.age, 30);
    });

    test('age does not roll over before birthday in current year', () {
      final now = DateTime.now();
      final dob = DateTime(now.year - 30, now.month, now.day)
          .add(const Duration(days: 1));
      final p = _make(dob: dob);
      expect(p.age, 29);
    });

    test('round-trips through JSON', () {
      final p = _make();
      final restored = Patient.fromJson(p.toJson());
      expect(restored.id, p.id);
      expect(restored.fullName, p.fullName);
      expect(restored.gender, p.gender);
      expect(restored.synced, p.synced);
    });
  });
}

Patient _make({DateTime? dob}) => Patient(
      id: 'pat-1',
      firstName: 'Asha',
      lastName: 'Mwangi',
      dateOfBirth: dob ?? DateTime(1990, 5, 1),
      gender: 'female',
      phone: '+254700000000',
      village: 'Kibera',
      facilityName: 'Local Clinic',
    );
