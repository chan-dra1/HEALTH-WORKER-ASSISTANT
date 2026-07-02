import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'home_screen.dart';

// One-time first-launch setup. Asks exactly ONE thing (the worker's
// name, used to sign records) and shows three picture cards explaining
// the app. Designed for users with basic phone skills: one screen, one
// text field, one big button.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name first.')),
      );
      return;
    }
    final db = DatabaseService();
    await db.setSetting('chw_name', name);
    await db.setSetting('onboarded', 'true');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[700],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.health_and_safety,
                    size: 72, color: Colors.white),
                const SizedBox(height: 8),
                const Text('HealthWorker',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold)),
                const Text('Works without internet. Always.',
                    style: TextStyle(color: Colors.white70, fontSize: 15)),
                const SizedBox(height: 24),
                const _ExplainCard(
                  icon: Icons.people,
                  title: 'Keep patient records',
                  body: 'Add patients and their vitals. '
                      'Everything is saved on this phone.',
                ),
                const _ExplainCard(
                  icon: Icons.checklist,
                  title: 'Check symptoms',
                  body: 'Tap the symptoms you see. The app shows possible '
                      'conditions from WHO guidelines — red means REFER.',
                ),
                const _ExplainCard(
                  icon: Icons.medication,
                  title: 'Calculate safe doses',
                  body: 'Enter the patient\'s weight and pick a medicine. '
                      'Always verify with your guidelines.',
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Your name',
                    hintText: 'e.g. Asha Mwangi',
                    helperText:
                        'Used to sign the records you create. Nothing is sent anywhere.',
                    helperStyle: const TextStyle(color: Colors.white70),
                    labelStyle: TextStyle(color: Colors.green[900]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green[800],
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _start,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Start'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplainCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _ExplainCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 36, color: Colors.green[700]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(body,
                      style:
                          TextStyle(color: Colors.grey[800], fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
