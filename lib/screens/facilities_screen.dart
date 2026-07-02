import 'package:flutter/material.dart';
import '../models/facility.dart';
import '../services/database_service.dart';

// Local facility directory the CHW maintains for their own area.
// We deliberately ship NO pre-loaded facility data: invented hospital
// names, coordinates, or phone numbers would be worse than none.
class FacilitiesScreen extends StatefulWidget {
  const FacilitiesScreen({Key? key}) : super(key: key);

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  late Future<List<Facility>> _facilities;
  String _query = '';

  static const _types = <String, IconData>{
    'hospital': Icons.local_hospital,
    'health-center': Icons.medical_services,
    'clinic': Icons.healing,
    'pharmacy': Icons.local_pharmacy,
  };

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _facilities = DatabaseService().getAllFacilities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Facilities'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by name or village',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (q) => setState(() => _query = q.toLowerCase()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Facility>>(
              future: _facilities,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var items = snap.data!;
                if (_query.isNotEmpty) {
                  items = items
                      .where((f) =>
                          f.name.toLowerCase().contains(_query) ||
                          f.village.toLowerCase().contains(_query))
                      .toList();
                }
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_city,
                              size: 64, color: Colors.grey[500]),
                          const SizedBox(height: 12),
                          Text(
                            _query.isEmpty
                                ? 'No facilities saved yet.\n\nAdd the hospitals, clinics and pharmacies in YOUR area so they are always available offline — including phone numbers for referral calls.'
                                : 'No match for "$_query".',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) => _facilityCard(items[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Add facility'),
        onPressed: _showAddDialog,
      ),
    );
  }

  Widget _facilityCard(Facility f) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        leading: Icon(_types[f.type] ?? Icons.location_on,
            color: Colors.green[700]),
        title: Text(f.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${f.type.replaceAll('-', ' ')} · ${f.village}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          if (f.phone.isNotEmpty)
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 8),
                SelectableText(f.phone),
              ],
            ),
          if (f.directions?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.directions, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f.directions!)),
                ],
              ),
            ),
          if (f.services?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.medical_information,
                      size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f.services!)),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete'),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete facility?'),
                    content: Text('Remove "${f.name}" from the directory?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await DatabaseService().deleteFacility(f.id);
                  _refresh();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final villageController = TextEditingController();
    final directionsController = TextEditingController();
    final servicesController = TextEditingController();
    String type = 'clinic';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Facility'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Facility name *'),
                ),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: _types.keys
                      .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.replaceAll('-', ' '))))
                      .toList(),
                  onChanged: (t) =>
                      setDialogState(() => type = t ?? 'clinic'),
                ),
                TextField(
                  controller: villageController,
                  decoration: const InputDecoration(
                      labelText: 'Village / town *'),
                ),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'Phone number'),
                ),
                TextField(
                  controller: directionsController,
                  decoration: const InputDecoration(
                      labelText: 'Directions (landmarks)'),
                ),
                TextField(
                  controller: servicesController,
                  decoration: const InputDecoration(
                      labelText: 'Services (e.g. maternity, lab)'),
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
                if (nameController.text.trim().isEmpty ||
                    villageController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                        content: Text('Name and village are required.')),
                  );
                  return;
                }
                final f = Facility(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  type: type,
                  phone: phoneController.text.trim(),
                  village: villageController.text.trim(),
                  directions: directionsController.text.trim().isEmpty
                      ? null
                      : directionsController.text.trim(),
                  services: servicesController.text.trim().isEmpty
                      ? null
                      : servicesController.text.trim(),
                );
                await DatabaseService().insertFacility(f);
                if (mounted) {
                  Navigator.pop(dialogContext);
                  _refresh();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
