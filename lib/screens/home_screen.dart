import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/database_service.dart';
import 'symptom_checker_screen.dart';
import 'dosage_calculator_screen.dart';
import 'patient_tracker_screen.dart';
import 'facilities_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Patient>> _patientsFuture;

  @override
  void initState() {
    super.initState();
    _refreshPatients();
  }

  void _refreshPatients() {
    setState(() {
      _patientsFuture = DatabaseService().getAllPatients();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text('HealthWorker'),
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
                  const Icon(Icons.people, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text('No patients yet',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _showAddPatientDialog,
                    child: const Text('Add First Patient'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(patient.fullName),
                  subtitle: Text(
                      '${patient.age} years old  |  ${patient.village}'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    // TODO: Navigate to patient detail screen
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPatientDialog,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddPatientDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final villageController = TextEditingController();
    String? selectedGender;
    DateTime? selectedDOB;

    showDialog(
      context: context,
      builder: (dialogContext) {
        // StatefulBuilder so the dialog itself rebuilds when the user
        // picks a gender or date of birth.
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Patient'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: firstNameController,
                      decoration:
                          const InputDecoration(labelText: 'First Name'),
                    ),
                    TextField(
                      controller: lastNameController,
                      decoration:
                          const InputDecoration(labelText: 'Last Name'),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration:
                          const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                    ),
                    TextField(
                      controller: villageController,
                      decoration:
                          const InputDecoration(labelText: 'Village'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      hint: const Text('Select Gender'),
                      value: selectedGender,
                      isExpanded: true,
                      items: const ['Male', 'Female', 'Other']
                          .map((g) => DropdownMenuItem(
                                value: g.toLowerCase(),
                                child: Text(g),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() => selectedGender = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDOB ?? DateTime(2000),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setDialogState(() => selectedDOB = date);
                        }
                      },
                      child: Text(selectedDOB == null
                          ? 'Select Date of Birth'
                          : selectedDOB!
                              .toLocal()
                              .toString()
                              .split(' ')[0]),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (firstNameController.text.isEmpty ||
                        selectedGender == null ||
                        selectedDOB == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content: Text('Please fill all fields')),
                      );
                      return;
                    }
                    final patient = Patient(
                      id: DateTime.now()
                          .millisecondsSinceEpoch
                          .toString(),
                      firstName: firstNameController.text,
                      lastName: lastNameController.text,
                      dateOfBirth: selectedDOB!,
                      gender: selectedGender!,
                      phone: phoneController.text,
                      village: villageController.text,
                      facilityName: 'Local Clinic',
                    );
                    await DatabaseService().insertPatient(patient);
                    if (!mounted) return;
                    Navigator.pop(dialogContext);
                    _refreshPatients();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.green[700]),
            child: const Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.health_and_safety,
                      color: Colors.white, size: 36),
                  SizedBox(height: 6),
                  Text('HealthWorker',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text('v0.1 · works offline',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
          _navTile(
            icon: Icons.people,
            label: 'Patients',
            onTap: () => Navigator.pop(context),
          ),
          _navTile(
            icon: Icons.checklist,
            label: 'Symptom checker',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SymptomCheckerScreen()));
            },
          ),
          _navTile(
            icon: Icons.medication_outlined,
            label: 'Dosage calculator',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DosageCalculatorScreen()));
            },
          ),
          _navTile(
            icon: Icons.monitor_heart,
            label: 'Vitals tracker',
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PatientTrackerScreen()));
              _refreshPatients();
            },
          ),
          _navTile(
            icon: Icons.location_city,
            label: 'Health facilities',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FacilitiesScreen()));
            },
          ),
          const Divider(),
          _navTile(
            icon: Icons.info_outline,
            label: 'About & limits',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _navTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      ListTile(
        leading: Icon(icon, color: Colors.green[700]),
        title: Text(label),
        onTap: onTap,
      );
}
