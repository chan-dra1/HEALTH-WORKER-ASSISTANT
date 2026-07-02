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

  // True for drugs dosed by AGE, not weight (vitamin A, zinc). For these
  // the app must never compute a weight-based dose: a heavy young infant
  // would be pushed into a higher band (e.g. 100,000 IU vitamin A at
  // 5 months when WHO says 50,000 IU under 6 months).
  final bool ageBased;

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
    this.ageBased = false,
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
      ageBased: json['ageBased'] as bool? ?? false,
    );
  }

  // Highest dose in the weight table — the per-drug ceiling for the
  // formula path. The table encodes each drug's true adult/maximum dose
  // (ibuprofen 400, ciprofloxacin 500, ferrous sulfate 60...), which a
  // flat global cap cannot.
  double? get _tableMax {
    if (dosageByWeight.isEmpty) return null;
    return dosageByWeight.values.reduce((a, b) => a > b ? a : b);
  }

  double? get _tableMinWeight {
    if (dosageByWeight.isEmpty) return null;
    return dosageByWeight.keys
        .map(double.parse)
        .reduce((a, b) => a < b ? a : b);
  }

  DoseResult doseFor(double weightKg) {
    if (weightKg <= 0) return DoseResult.unknown(unit);

    if (ageBased) {
      return DoseResult.ageBased(
        unit,
        ageRestrictions ?? notes ?? 'Dose by age — see notes.',
      );
    }

    // Formula path: mg/kg × weight, capped at THIS drug's maximum.
    if (mgPerKg != null && mgPerKg! > 0) {
      final raw = mgPerKg! * weightKg;
      final cap = _tableMax ?? (unit == 'mg' ? 1000.0 : null);
      final amount = (cap != null && raw > cap) ? cap : raw;
      return DoseResult(
        amount: amount,
        unit: unit,
        formula:
            '${_trim(mgPerKg!)}/kg × ${_trim(weightKg)} kg',
        capped: cap != null && raw > cap,
      );
    }

    // Table path: FLOOR lookup — the largest bucket at or below the
    // patient's weight. Nearest-neighbor would jump WHO weight bands
    // early (a 14.9 kg child snapping to the 15 kg artemether-
    // lumefantrine bucket doubles the dose).
    final minW = _tableMinWeight;
    if (minW == null) return DoseResult.unknown(unit);
    if (weightKg < minW) {
      return DoseResult.belowTable(
        unit,
        'Below the dosing table (${_trim(minW)} kg minimum). '
        'Check age restrictions or refer.',
      );
    }
    double floorWeight = -1;
    double dose = 0;
    dosageByWeight.forEach((k, v) {
      final w = double.parse(k);
      if (w <= weightKg && w > floorWeight) {
        floorWeight = w;
        dose = v;
      }
    });
    if (dose == 0) {
      return DoseResult.notRecommended(
        unit,
        ageRestrictions ?? 'Not recommended at this weight/age.',
      );
    }
    return DoseResult(
      amount: dose,
      unit: unit,
      formula: 'WHO band at ${_trim(floorWeight)} kg and above',
      capped: false,
    );
  }

  static String _trim(double v) =>
      v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

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

  // Set when no numeric dose should be shown; explains why.
  final String? reason;

  DoseResult({
    required this.amount,
    required this.unit,
    required this.formula,
    required this.capped,
  })  : isKnown = true,
        reason = null;

  DoseResult.unknown(this.unit)
      : amount = 0,
        formula = '',
        capped = false,
        isKnown = false,
        reason = 'No dose data available.';

  DoseResult.ageBased(this.unit, String detail)
      : amount = 0,
        formula = '',
        capped = false,
        isKnown = false,
        reason = 'Dosed by AGE, not weight. $detail';

  DoseResult.belowTable(this.unit, String detail)
      : amount = 0,
        formula = '',
        capped = false,
        isKnown = false,
        reason = detail;

  DoseResult.notRecommended(this.unit, String detail)
      : amount = 0,
        formula = '',
        capped = false,
        isKnown = false,
        reason = 'Not recommended. $detail';

  String format() {
    if (!isKnown) return reason ?? 'No dose data';
    final cap = capped ? ' (capped at maximum)' : '';
    return '${Medication._trim(amount)} $unit$cap';
  }
}
