import 'package:flutter/material.dart';

// Plain statement of what this app is and is not. Shown from the drawer.
// A health tool earns trust by being explicit about its limits.
class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About & Limits'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Section(
            icon: Icons.health_and_safety,
            title: 'What this app is',
            body:
                'HealthWorker is an offline decision-support tool for trained '
                'Community Health Workers. It keeps patient records, suggests '
                'possible conditions from symptoms using WHO IMCI '
                'classifications, calculates weight-based drug doses from WHO '
                'reference tables, and stores your local facility contacts. '
                'Everything works without internet and stays on this device.',
          ),
          _Section(
            icon: Icons.block,
            title: 'What this app is NOT',
            body:
                '• It is not a doctor and does not diagnose. The symptom '
                'checker ranks POSSIBLE conditions to support — never replace '
                '— your training and judgment.\n\n'
                '• It does not know the patient in front of you. Allergies, '
                'pregnancy, malnutrition, and other conditions change what is '
                'safe.\n\n'
                '• It cannot detect every emergency. When in doubt, refer.\n\n'
                '• It does not send data anywhere. Nothing is uploaded; if '
                'the phone is lost, records on it are lost too unless your '
                'program backs them up.',
          ),
          _Section(
            icon: Icons.rule,
            title: 'Rules of use',
            body:
                '1. A RED "REFER" result means refer. Do not treat and wait.\n'
                '2. Verify every dose against your national guidelines — '
                'they take precedence over this app.\n'
                '3. Check contraindications before giving any drug.\n'
                '4. If the app and your training disagree, trust your '
                'training and report the issue.',
          ),
          _Section(
            icon: Icons.menu_book,
            title: 'Where the data comes from',
            body:
                'Condition classifications: WHO IMCI Chart Booklet (2014) and '
                'related WHO disease guidelines.\n\n'
                'Drug doses: WHO Pocket Book of Hospital Care for Children '
                '(2nd ed., 2013), WHO Model List of Essential Medicines for '
                'Children (2023), BNF for Children, WHO malaria treatment '
                'guidelines.\n\n'
                'Every condition and drug entry cites its source — tap any '
                'result to see it. Facility contacts are entered by you; the '
                'app ships with none, because invented hospital data would be '
                'dangerous.',
          ),
          _Section(
            icon: Icons.code,
            title: 'Open source',
            body:
                'Free forever, AGPL-3.0 licensed. Report errors or contribute '
                'at github.com/chan-dra1/HEALTH-WORKER-ASSISTANT. If you find '
                'a dosing error, please report it immediately.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Section({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green[700]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(body, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}
