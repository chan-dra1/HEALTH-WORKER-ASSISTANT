import 'package:flutter/material.dart';
import '../models/symptom_condition.dart';
import '../services/symptom_engine.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({Key? key}) : super(key: key);

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final _engine = SymptomEngine();
  late Future<void> _load;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _load = _engine.load();
  }

  String _pretty(String slug) =>
      slug.replaceAll('-', ' ').replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Checker'),
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
                child: Text('Could not load symptom database:\n'
                    '${snap.error}'),
              ),
            );
          }
          final symptoms = _engine.allSymptoms;
          final matches = _engine.match(_selected);

          return Column(
            children: [
              _DisclaimerBanner(text: _engine.disclaimer),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const Text('Select symptoms',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: symptoms.map((s) {
                        final on = _selected.contains(s);
                        return FilterChip(
                          label: Text(_pretty(s)),
                          selected: on,
                          onSelected: (_) {
                            setState(() {
                              if (on) {
                                _selected.remove(s);
                              } else {
                                _selected.add(s);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text('Likely conditions',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_selected.isEmpty)
                      const Text(
                          'Select one or more symptoms above to see matches.')
                    else if (matches.isEmpty)
                      const Text(
                          'No conditions match. Refer the patient if symptoms are severe or unclear.')
                    else
                      ...matches.map(_buildMatchCard),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(ConditionMatch m) {
    final c = m.condition;
    final pct = (m.matchPercent * 100).round();
    final severeColor = _severityColor(c.severity);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: severeColor,
          child: Text('$pct',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        title: Text(c.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${m.matchedCount}/${m.totalSymptoms} symptoms · '
          '${c.severity}${c.referralNeeded ? ' · REFER' : ''}',
          style: TextStyle(
              color: c.referralNeeded ? Colors.red[700] : null,
              fontWeight:
                  c.referralNeeded ? FontWeight.bold : FontWeight.normal),
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (c.referralNeeded && c.referralCriteria != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(c.referralCriteria!,
                          style: TextStyle(color: Colors.red[900]))),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _kv('Treatment', c.treatment),
          if (c.medications.isNotEmpty)
            _kv('Medications', c.medications.join(', ')),
          _kv('Age group', _pretty(c.ageGroup)),
          if (c.sources.isNotEmpty)
            _kv('Source', c.sources.join('\n')),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(top: 6),
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

  Color _severityColor(String s) {
    switch (s) {
      case 'severe':
        return Colors.red[700]!;
      case 'moderate':
        return Colors.orange[700]!;
      case 'mild':
        return Colors.green[700]!;
      default:
        return Colors.grey[600]!;
    }
  }
}

class _DisclaimerBanner extends StatelessWidget {
  final String text;
  const _DisclaimerBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.amber[100],
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber[900], size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: Colors.amber[900], fontSize: 12))),
        ],
      ),
    );
  }
}
