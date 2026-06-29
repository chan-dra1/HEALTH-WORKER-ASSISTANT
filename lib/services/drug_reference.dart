import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/medication.dart';

class DrugReference {
  static final DrugReference _instance = DrugReference._internal();
  factory DrugReference() => _instance;
  DrugReference._internal();

  List<Medication>? _meds;
  String _disclaimer = '';
  String _version = '';

  Future<void> load() async {
    if (_meds != null) return;
    final raw =
        await rootBundle.loadString('assets/data/drug_reference.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _version = json['version'] as String? ?? '0.0.0';
    _disclaimer = json['disclaimer'] as String? ?? '';
    final list = json['medications'] as List;
    _meds = list
        .map((m) => Medication.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  List<Medication> get all => _meds ?? const [];
  String get disclaimer => _disclaimer;
  String get version => _version;

  Medication? byName(String name) {
    for (final m in all) {
      if (m.name.toLowerCase() == name.toLowerCase()) return m;
    }
    return null;
  }
}
