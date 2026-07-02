import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/observation.dart';
import '../models/patient.dart';
import '../services/database_service.dart';

class PatientTrackerScreen extends StatefulWidget {
  const PatientTrackerScreen({Key? key}) : super(key: key);

  @override
  State<PatientTrackerScreen> createState() => _PatientTrackerScreenState();
}

class _PatientTrackerScreenState extends State<PatientTrackerScreen> {
  final _db = DatabaseService();
  late Future<List<Patient>> _patients;
  Patient? _selected;

  @override
  void initState() {
    super.initState();
    _patients = _db.getAllPatients();
  }

  Future<void> _refreshSelectedPatient() async {
    if (_selected == null) return;
    final p = await _db.getPatient(_selected!.id);
    if (mounted && p != null) setState(() => _selected = p);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitals Tracker'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Patient>>(
        future: _patients,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final patients = snap.data!;
          if (patients.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                    'No patients yet. Add one from Home before recording vitals.',
                    textAlign: TextAlign.center),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<Patient>(
                  value: _selected,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Patient',
                    border: OutlineInputBorder(),
                  ),
                  items: patients
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                                '${p.fullName} · ${p.age}y · ${p.village}'),
                          ))
                      .toList(),
                  onChanged: (p) => setState(() => _selected = p),
                ),
                const SizedBox(height: 16),
                if (_selected != null)
                  Expanded(child: _VitalsView(patient: _selected!))
                else
                  const Expanded(
                    child: Center(child: Text('Select a patient.')),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _selected == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Record vitals'),
              onPressed: () async {
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) =>
                      _RecordVitalsSheet(patient: _selected!),
                );
                await _refreshSelectedPatient();
                setState(() {});
              },
            ),
    );
  }
}

class _VitalsView extends StatelessWidget {
  final Patient patient;
  const _VitalsView({required this.patient});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Observation>>(
      future: DatabaseService().getPatientObservations(patient.id),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final obs = snap.data!;
        if (obs.isEmpty) {
          return const Center(child: Text('No vitals recorded yet.'));
        }

        final temps = obs.where((o) => o.type == 'temperature').toList();

        return ListView(
          children: [
            if (temps.length >= 2) _TemperatureChart(observations: temps),
            const SizedBox(height: 8),
            const Text('History',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...obs.map((o) => Card(
                  child: ListTile(
                    leading: Icon(_iconFor(o.type),
                        color: Colors.green[700]),
                    title: Text(
                        '${o.value.toStringAsFixed(1)} ${o.unit} · ${_label(o.type)}'),
                    subtitle: Text(
                        '${o.recordedAt.toLocal().toString().split('.')[0]} · by ${o.recordedBy}'),
                  ),
                )),
          ],
        );
      },
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'temperature':
        return Icons.thermostat;
      case 'blood_pressure':
        return Icons.favorite;
      case 'weight':
        return Icons.monitor_weight;
      default:
        return Icons.science;
    }
  }

  String _label(String type) {
    switch (type) {
      case 'temperature':
        return 'Temperature';
      case 'blood_pressure':
        return 'Blood pressure (systolic)';
      case 'weight':
        return 'Weight';
      default:
        return type;
    }
  }
}

class _TemperatureChart extends StatelessWidget {
  final List<Observation> observations;
  const _TemperatureChart({required this.observations});

  @override
  Widget build(BuildContext context) {
    // fl_chart expects ascending x — observations come back DESC.
    final asc = observations.reversed.toList();
    final spots = <FlSpot>[
      for (var i = 0; i < asc.length; i++)
        FlSpot(i.toDouble(), asc[i].value),
    ];

    return SizedBox(
      height: 180,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: LineChart(
          LineChartData(
            minY: 35,
            maxY: 42,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}°',
                        style: const TextStyle(fontSize: 10))),
              ),
              bottomTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: true),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.red,
                barWidth: 3,
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordVitalsSheet extends StatefulWidget {
  final Patient patient;
  const _RecordVitalsSheet({required this.patient});

  @override
  State<_RecordVitalsSheet> createState() => _RecordVitalsSheetState();
}

class _RecordVitalsSheetState extends State<_RecordVitalsSheet> {
  String _type = 'temperature';
  final _valueController = TextEditingController();
  final _recordedByController = TextEditingController(text: 'CHW');

  @override
  void initState() {
    super.initState();
    // Pre-fill with the name captured at first-run setup.
    DatabaseService().getSetting('chw_name').then((name) {
      if (mounted && name != null && name.isNotEmpty) {
        _recordedByController.text = name;
      }
    });
  }

  @override
  void dispose() {
    _valueController.dispose();
    _recordedByController.dispose();
    super.dispose();
  }

  String get _unit {
    switch (_type) {
      case 'temperature':
        return 'C';
      case 'blood_pressure':
        return 'mmHg';
      case 'weight':
        return 'kg';
      default:
        return '';
    }
  }

  // Tight clinical sanity ranges. Anything outside these and we bail —
  // forces the worker to double-check before they save bad data.
  String? _validate(double v) {
    switch (_type) {
      case 'temperature':
        if (v < 30 || v > 45) return 'Temperature must be 30–45 °C.';
        break;
      case 'blood_pressure':
        if (v < 50 || v > 250) return 'Systolic BP must be 50–250 mmHg.';
        break;
      case 'weight':
        if (v <= 0 || v > 250) return 'Weight must be 0–250 kg.';
        break;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Record vitals for ${widget.patient.fullName}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'temperature',
                  label: Text('Temp'),
                  icon: Icon(Icons.thermostat)),
              ButtonSegment(
                  value: 'blood_pressure',
                  label: Text('BP'),
                  icon: Icon(Icons.favorite)),
              ButtonSegment(
                  value: 'weight',
                  label: Text('Weight'),
                  icon: Icon(Icons.monitor_weight)),
            ],
            selected: {_type},
            onSelectionChanged: (s) =>
                setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Value ($_unit)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _recordedByController,
            decoration: const InputDecoration(
              labelText: 'Recorded by',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  final v = double.tryParse(_valueController.text);
                  if (v == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a number.')),
                    );
                    return;
                  }
                  final err = _validate(v);
                  if (err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err)),
                    );
                    return;
                  }
                  final obs = Observation(
                    id: DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(),
                    patientId: widget.patient.id,
                    type: _type,
                    value: v,
                    unit: _unit,
                    recordedBy: _recordedByController.text.isEmpty
                        ? 'CHW'
                        : _recordedByController.text,
                  );
                  await DatabaseService().insertObservation(obs);
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
