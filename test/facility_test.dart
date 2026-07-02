import 'package:flutter_test/flutter_test.dart';
import 'package:healthworker/models/facility.dart';

void main() {
  group('Facility', () {
    test('round-trips through JSON', () {
      final f = Facility(
        id: 'fac-1',
        name: 'St. Mary Health Center',
        type: 'health-center',
        phone: '+255700000000',
        village: 'Mwanza',
        directions: 'Past the market, blue gate',
        services: 'maternity, lab',
      );
      final restored = Facility.fromJson(f.toJson());
      expect(restored.id, f.id);
      expect(restored.name, f.name);
      expect(restored.type, f.type);
      expect(restored.directions, f.directions);
      expect(restored.services, f.services);
    });

    test('handles missing optional fields', () {
      final f = Facility.fromJson({
        'id': 'fac-2',
        'name': 'Clinic',
        'type': 'clinic',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      });
      expect(f.phone, '');
      expect(f.village, '');
      expect(f.directions, isNull);
      expect(f.services, isNull);
    });
  });
}
