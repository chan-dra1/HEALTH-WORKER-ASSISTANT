import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/drug_reference.dart';

class DosageCalculatorScreen extends StatefulWidget {
  const DosageCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<DosageCalculatorScreen> createState() =>
      _DosageCalculatorScreenState();
}

class _DosageCalculatorScreenState extends State<DosageCalculatorScreen> {
  final _ref = DrugReference();
  final _weightController = TextEditingController();
  late Future<void> _load;
  Medication? _selected;

  @override
  void initState() {
    super.initState();
    _load = _ref.load();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  double? get _weight => double.tryParse(_weightController.text);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dosage Calculator'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<void>(
        future: _load,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                    'Could not load drug reference:\n${snap.error}'),
              ),
            );
          }

          final meds = _ref.all;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_ref.disclaimer.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.amber[900], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_ref.disclaimer,
                            style: TextStyle(
                                color: Colors.amber[900], fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Patient weight (kg)',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Medication>(
                value: _selected,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Medication',
                  prefixIcon: Icon(Icons.medication_outlined),
                  border: OutlineInputBorder(),
                ),
                items: meds
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.name),
                        ))
                    .toList(),
                onChanged: (m) => setState(() => _selected = m),
              ),
              const SizedBox(height: 24),
              if (_selected != null) _buildResult(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResult() {
    final m = _selected!;
    final w = _weight;
    if (w == null || w <= 0) {
      return _infoCard(m);
    }
    final dose = m.doseFor(w);

    // Non-numeric outcome (age-based drug, weight below table, not
    // recommended): show the reason prominently, never a number.
    if (!dose.isKnown) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[900]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(dose.reason ?? 'No dose available.',
                        style: TextStyle(
                            color: Colors.orange[900],
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _infoCard(m),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Colors.green[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calculated dose',
                    style: TextStyle(
                        color: Colors.green[900],
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(dose.format(),
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                if (dose.formula.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(dose.formula,
                        style: TextStyle(
                            color: Colors.green[800], fontSize: 12)),
                  ),
                if (m.frequency != null) ...[
                  const SizedBox(height: 8),
                  Text('Frequency: ${m.frequency}',
                      style: const TextStyle(fontSize: 13)),
                ],
                if (m.maxDailyDose != null)
                  Text('Max: ${m.maxDailyDose}',
                      style: const TextStyle(fontSize: 13)),
                if (m.route != null)
                  Text('Route: ${m.route}',
                      style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _infoCard(m),
      ],
    );
  }

  Widget _infoCard(Medication m) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.name,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(m.type,
                style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            if (m.indications.isNotEmpty) ...[
              const SizedBox(height: 10),
              _kv('Indications', m.indications.join(', ')),
            ],
            if (m.ageRestrictions != null)
              _kv('Age / restrictions', m.ageRestrictions!),
            if (m.sideEffects.isNotEmpty)
              _kv('Side effects', m.sideEffects.join(', ')),
            if (m.contraindications.isNotEmpty)
              _kv('Contraindications', m.contraindications),
            if (m.notes != null) _kv('Notes', m.notes!),
            if (m.sources.isNotEmpty) _kv('Source', m.sources.join('\n')),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 2),
            Text(v),
          ],
        ),
      );
}
