import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/database_service.dart';
import 'patient_detail_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({Key? key}) : super(key: key);

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  late Future<List<Patient>> _patientsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _patientsFuture = DatabaseService().getAllPatients();
    });
  }

  Future<void> _addPatient() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddPatientScreen()),
    );
    if (added == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Patient>>(
        future: _patientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final patients = snapshot.data ?? [];
          if (patients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No patients yet',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _addPatient,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add first patient',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final p = patients[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Text(
                      p.firstName.isNotEmpty
                          ? p.firstName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          color: Colors.green[900],
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(p.fullName,
                      style: const TextStyle(fontSize: 16)),
                  subtitle:
                      Text('${p.age} years old  |  ${p.village}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PatientDetailScreen(patient: p),
                      ),
                    );
                    // Refresh regardless of result: the patient may
                    // have been deleted or had vitals recorded.
                    _refresh();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPatient,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add patient'),
      ),
    );
  }
}

// Full-screen form: one field per line, large text, clear buttons.
// Much easier than a cramped dialog on a small phone.
class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({Key? key}) : super(key: key);

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _village = TextEditingController();
  String? _gender;
  DateTime? _dob;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _village.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      );

  Future<void> _save() async {
    if (_firstName.text.trim().isEmpty ||
        _gender == null ||
        _dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('First name, gender and date of birth are needed.')),
      );
      return;
    }
    final patient = Patient(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      dateOfBirth: _dob!,
      gender: _gender!,
      phone: _phone.text.trim(),
      village: _village.text.trim(),
      facilityName: 'Local Clinic',
    );
    await DatabaseService().insertPatient(patient);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Patient'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _firstName,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 17),
            decoration: _dec('First name *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lastName,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 17),
            decoration: _dec('Last name'),
          ),
          const SizedBox(height: 12),
          // Gender as big tap targets, not a dropdown.
          Text('Gender *',
              style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'female', label: Text('Female'), icon: Icon(Icons.female)),
              ButtonSegment(
                  value: 'male', label: Text('Male'), icon: Icon(Icons.male)),
              ButtonSegment(value: 'other', label: Text('Other')),
            ],
            selected: _gender == null ? <String>{} : {_gender!},
            emptySelectionAllowed: true,
            onSelectionChanged: (s) =>
                setState(() => _gender = s.isEmpty ? null : s.first),
          ),
          const SizedBox(height: 16),
          // DOB as a big button that opens the date picker.
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.cake),
              label: Text(
                _dob == null
                    ? 'Select date of birth *'
                    : 'Born: ${_dob!.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(fontSize: 16),
              ),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dob ?? DateTime(2015),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _dob = date);
              },
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _village,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 17),
            decoration: _dec('Village / town'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 17),
            decoration: _dec('Phone (optional)'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Save patient'),
            ),
          ),
        ],
      ),
    );
  }
}
