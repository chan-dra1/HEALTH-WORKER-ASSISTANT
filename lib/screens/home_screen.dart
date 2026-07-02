import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'patients_screen.dart';
import 'symptom_checker_screen.dart';
import 'dosage_calculator_screen.dart';
import 'patient_tracker_screen.dart';
import 'facilities_screen.dart';
import 'about_screen.dart';

// Home is a dashboard of six large picture-buttons. Nothing is hidden
// behind menus: a first-time user sees every feature at once and each
// tile says what it does in one line.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _chwName = '';
  int _patientCount = 0;

  @override
  void initState() {
    super.initState();
    _loadHeader();
  }

  Future<void> _loadHeader() async {
    final db = DatabaseService();
    final name = await db.getSetting('chw_name') ?? '';
    final patients = await db.getAllPatients();
    if (!mounted) return;
    setState(() {
      _chwName = name;
      _patientCount = patients.length;
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => screen));
    _loadHeader(); // refresh count when coming back
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Greeting header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.health_and_safety,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      const Text('HealthWorker',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.wifi_off,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('offline',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _chwName.isEmpty ? 'Welcome' : 'Hello, $_chwName',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$_patientCount patient${_patientCount == 1 ? '' : 's'} on this phone',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            // Feature tiles
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: [
                  _Tile(
                    icon: Icons.people,
                    color: Colors.blue,
                    title: 'Patients',
                    subtitle: 'Add and view records',
                    onTap: () => _open(const PatientsScreen()),
                  ),
                  _Tile(
                    icon: Icons.checklist,
                    color: Colors.orange,
                    title: 'Symptoms',
                    subtitle: 'Check possible conditions',
                    onTap: () => _open(const SymptomCheckerScreen()),
                  ),
                  _Tile(
                    icon: Icons.medication,
                    color: Colors.purple,
                    title: 'Medicine dose',
                    subtitle: 'Safe dose by weight',
                    onTap: () => _open(const DosageCalculatorScreen()),
                  ),
                  _Tile(
                    icon: Icons.monitor_heart,
                    color: Colors.red,
                    title: 'Vitals',
                    subtitle: 'Temperature, BP, weight',
                    onTap: () => _open(const PatientTrackerScreen()),
                  ),
                  _Tile(
                    icon: Icons.location_city,
                    color: Colors.teal,
                    title: 'Facilities',
                    subtitle: 'Your local clinics',
                    onTap: () => _open(const FacilitiesScreen()),
                  ),
                  _Tile(
                    icon: Icons.info_outline,
                    color: Colors.blueGrey,
                    title: 'About & limits',
                    subtitle: 'What this app is not',
                    onTap: () => _open(const AboutScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final MaterialColor color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color[50],
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const Spacer(),
              Text(title,
                  style: TextStyle(
                      color: color[900],
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(color: color[800], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
