import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/observation.dart';
import '../models/patient.dart';
import '../services/database_service.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;
  const PatientDetailScreen({Key? key, required this.patient})
      : super(key: key);

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  late Future<List<Observation>> _observationsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _observationsFuture =
          DatabaseService().getPatientObservations(widget.patient.id);
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete patient?'),
        content: Text(
            'Remove ${widget.patient.fullName} from this device? '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await DatabaseService().deletePatient(widget.patient.id);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _recordVitals() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RecordVitalsSheet(patient: widget.patient),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    return Scaffold(
      appBar: AppBar(
        title: Text(p.fullName),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete patient',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          _HeaderCard(patient: p),
          const SizedBox(height: 16),
          const Text('Vitals history',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FutureBuilder<List<Observation>>(
            future: _observationsFuture,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final obs = snap.data!;
              if (obs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No vitals recorded yet.\nTap "Record vitals" to add the first one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                  ),
                );
              }
              final temps =
                  obs.where((o) => o.type == 'temperature').toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (temps.length >= 2)
                    _TemperatureChart(observations: temps),
                  ...obs.map((o) => Card(
                        child: ListTile(
                          leading: Icon(_iconFor(o.type),
                              color: Colors.green[700]),
                          title: Text(
                              '${o.value.toStringAsFixed(1)} ${o.unit} · ${_label(o.type)}',
                              style: const TextStyle(fontSize: 16)),
                          subtitle: Text(
                              '${o.recordedAt.toLocal().toString().split('.')[0]} · by ${o.recordedBy}'),
                        ),
                      )),
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _recordVitals,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Record vitals'),
      ),
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

class _HeaderCard extends StatelessWidget {
  final Patient patient;
  const _HeaderCard({required this.patient});

  String _genderLabel(String gender) {
    switch (gender) {
      case 'female':
        return 'Female';
      case 'male':
        return 'Male';
      default:
        return 'Other';
    }
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.green[700]),
          const SizedBox(width: 12),
          Text('$label: ',
              style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = patient;
    final dob = p.dateOfBirth.toLocal().toString().split(' ')[0];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(Icons.cake, 'Age', '${p.age} years'),
            _row(Icons.person, 'Gender', _genderLabel(p.gender)),
            _row(Icons.home, 'Village',
                p.village.isEmpty ? 'Not recorded' : p.village),
            _row(Icons.phone, 'Phone',
                p.phone.isEmpty ? 'Not recorded' : p.phone),
            _row(Icons.event, 'Date of birth', dob),
          ],
        ),
      ),
    );
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

  Future<void> _save() async {
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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInsets.bottom),
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
            onSelectionChanged: (s) => setState(() => _type = s.first),
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
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
