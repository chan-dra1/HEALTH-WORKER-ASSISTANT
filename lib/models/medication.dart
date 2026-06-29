class Medication {
  final String name;
  final String type;
  final List<String> indications;
  final double? mgPerKg;
  final Map<String, double> dosageByWeight; // weight kg -> dose (unit)
  final String unit;
  final String? frequency;
  final String? maxDailyDose;
  final String? route;
  final String? ageRestrictions;
  final List<String> sideEffects;
  final String contraindications;
  final String? notes;
  final List<String> sources;

  Medication({
    required this.name,
    required this.type,
    required this.dosageByWeight,
    required this.unit,
    required this.sideEffects,
    required this.contraindications,
    this.indications = const [],
    this.mgPerKg,
    this.frequency,
    this.maxDailyDose,
    this.route,
    this.ageRestrictions,
    this.notes,
    this.sources = const [],
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    final raw = (json['dosageByWeight'] as Map?) ?? const {};
    final dosage = <String, double>{};
    raw.forEach((k, v) {
      dosage[k.toString()] = (v as num).toDouble();
    });
    return Medication(
      name: json['name'] as String,
      type: json['type'] as String? ?? '',
      indications:
          List<String>.from((json['indications'] as List?) ?? const []),
      mgPerKg: (json['mgPerKg'] as num?)?.toDouble(),
      dosageByWeight: dosage,
      unit: json['unit'] as String? ?? 'mg',
      frequency: json['frequency'] as String?,
      maxDailyDose: json['maxDailyDose'] as String?,
      route: json['route'] as String?,
      ageRestrictions: json['ageRestrictions'] as String?,
      sideEffects:
          List<String>.from((json['sideEffects'] as List?) ?? const []),
      contraindications: json['contraindications'] as String? ?? '',
      notes: json['notes'] as String?,
      sources: List<String>.from((json['sources'] as List?) ?? const []),
    );
  }

  // Calculate dose for a weight. Prefers mg/kg formula when available
  // (most clinically accurate), falls back to the lookup table.
  DoseResult doseFor(double weightKg) {
    if (mgPerKg != null && mgPerKg! > 0) {
      final raw = mgPerKg! * weightKg;
      final capped = _capAtAdultMax(raw);
      return DoseResult(
        amount: capped,
        unit: unit,
        formula: '${mgPerKg!.toStringAsFixed(1)} $unit/kg × '
            '${weightKg.toStringAsFixed(1)} kg',
        capped: capped < raw,
      );
    }
    // Table fallback: find closest weight bucket.
    double? closest;
    double minDiff = double.infinity;
    dosageByWeight.forEach((w, _) {
      final diff = (double.parse(w) - weightKg).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = double.parse(w);
      }
    });
    if (closest == null) return DoseResult.unknown(unit);
    final dose = dosageByWeight[closest!.toStringAsFixed(1)]!;
    return DoseResult(
      amount: dose,
      unit: unit,
      formula:
          'Lookup at ${closest!.toStringAsFixed(1)} kg (approx)',
      capped: false,
    );
  }

  // Approximate ceiling at standard adult max for table-less calc.
  // Most pediatric drugs cap around the listed max in `maxDailyDose`,
  // but for a single dose, paracetamol/ibuprofen cap at 1000/400 mg, etc.
  // We use 1000 mg as a conservative single-dose ceiling.
  double _capAtAdultMax(double mg) {
    const adultSingleDoseCeilingMg = 1000.0;
    if (unit != 'mg') return mg;
    return mg > adultSingleDoseCeilingMg
        ? adultSingleDoseCeilingMg
        : mg;
  }

  // Legacy helper retained for back-compat with earlier callers.
  String? getDosage(double weightKg) {
    final r = doseFor(weightKg);
    return r.isKnown ? r.format() : null;
  }
}

class DoseResult {
  final double amount;
  final String unit;
  final String formula;
  final bool capped;
  final bool isKnown;

  DoseResult({
    required this.amount,
    required this.unit,
    required this.formula,
    required this.capped,
  }) : isKnown = true;

  DoseResult.unknown(this.unit)
      : amount = 0,
        formula = '',
        capped = false,
        isKnown = false;

  String format() {
    if (!isKnown) return 'No dose data';
    final cap = capped ? ' (capped at adult max)' : '';
    return '${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 1)} $unit$cap';
  }
}
