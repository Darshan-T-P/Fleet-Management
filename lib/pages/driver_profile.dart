import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/cloudinary_service.dart';

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _licenseExpiryController =
      TextEditingController();
  final List<String> _vehicleTypeOptions = const [
    "Car",
    "Truck",
    "Bus",
    "Van",
    "SUV",
    "Mini Truck",
  ];
  final Set<String> _selectedVehicleTypes = {};
  bool _licenseVerificationRequested = false;
  bool _loading = true;
  String? _licenseImageUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data() ?? {};

    final profile = data['profile'] as Map<String, dynamic>? ?? {};
    _ageController.text = (profile['age']?.toString() ?? '');
    _experienceController.text = (profile['experienceYears']?.toString() ?? '');
    _licenseNumberController.text = (profile['licenseNumber'] ?? '');
    _licenseExpiryController.text = (profile['licenseExpiry'] ?? '');
    _licenseImageUrl = profile['licenseImageUrl'];
    final types =
        (profile['vehicleTypes'] as List?)?.cast<String>().toList() ?? [];
    _selectedVehicleTypes.addAll(types);
    _licenseVerificationRequested =
        (profile['licenseVerificationRequested'] ?? false) as bool;

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'profile': {
        'age': int.tryParse(_ageController.text),
        'experienceYears': int.tryParse(_experienceController.text),
        'vehicleTypes': _selectedVehicleTypes.toList(),
        'licenseNumber': _licenseNumberController.text.trim(),
        'licenseExpiry': _licenseExpiryController.text.trim(),
        'licenseVerificationRequested': _licenseVerificationRequested,
        'licenseImageUrl': _licenseImageUrl,
      },
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile saved')));
  }

  Future<void> _pickAndUploadLicense() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: false,
    );
    if (res == null || res.files.single.path == null) return;
    final path = res.files.single.path!;
    setState(() => _uploading = true);
    try {
      const cloudName = 'dyiujbjfb';
      const preset = 'fleet-management';
      final url = await CloudinaryService(
        cloudName: cloudName,
        unsignedPreset: preset,
      ).uploadImageFile(File(path));
      if (url != null) {
        setState(() => _licenseImageUrl = url);
        await _saveProfile();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload failed')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
            tooltip: 'Save',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _ageController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Age',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _experienceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Experience (years)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Vehicle Types',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _vehicleTypeOptions.map((type) {
                              final selected = _selectedVehicleTypes.contains(
                                type,
                              );
                              return ChoiceChip(
                                label: Text(type),
                                selected: selected,
                                onSelected: (v) {
                                  setState(() {
                                    if (v) {
                                      _selectedVehicleTypes.add(type);
                                    } else {
                                      _selectedVehicleTypes.remove(type);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'License',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _licenseNumberController,
                            decoration: const InputDecoration(
                              labelText: 'License Number',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _licenseExpiryController,
                            decoration: const InputDecoration(
                              labelText: 'Expiry (YYYY-MM-DD)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _uploading
                                    ? null
                                    : _pickAndUploadLicense,
                                icon: const Icon(Icons.upload_file),
                                label: Text(
                                  _uploading
                                      ? 'Uploading...'
                                      : 'Upload License Image',
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (_licenseImageUrl != null)
                                TextButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_licenseImageUrl != null)
                                              Image.network(_licenseImageUrl!),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Preview'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Request license verification'),
                            value: _licenseVerificationRequested,
                            onChanged: (v) => setState(
                              () => _licenseVerificationRequested = v,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _LicenseStatus(
                            uid: FirebaseAuth.instance.currentUser!.uid,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const _EfficiencySection(),
                ],
              ),
            ),
    );
  }
}

class _LicenseStatus extends StatelessWidget {
  final String uid;
  const _LicenseStatus({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final verified = (data['profile']?['licenseVerified'] ?? false) as bool;
        return Row(
          children: [
            Icon(
              verified ? Icons.verified : Icons.verified_outlined,
              color: verified ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(verified ? 'License Verified' : 'License not verified'),
          ],
        );
      },
    );
  }
}

class _EfficiencySection extends StatelessWidget {
  const _EfficiencySection();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Driving Efficiency',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('trips')
                  .where('driverId', isEqualTo: uid)
                  .where('status', isEqualTo: 'Completed')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final trips = snapshot.data!.docs;
                if (trips.isEmpty) return const Text('No completed trips yet');

                int onTimeCount = 0;
                int withExpected = 0;
                for (final d in trips) {
                  final data = d.data() as Map<String, dynamic>;
                  final expected = (data['expectedDurationMin'] ?? 0)
                      .toDouble();
                  final startedAt = data['startedAt'] is Timestamp
                      ? (data['startedAt'] as Timestamp).toDate()
                      : null;
                  final completedAt = data['completedAt'] is Timestamp
                      ? (data['completedAt'] as Timestamp).toDate()
                      : null;
                  if (expected > 0 &&
                      startedAt != null &&
                      completedAt != null) {
                    withExpected++;
                    final actual = completedAt
                        .difference(startedAt)
                        .inMinutes
                        .toDouble();
                    if (actual <= expected * 1.2) onTimeCount++;
                  }
                }

                final efficiency = withExpected == 0
                    ? 0.0
                    : (onTimeCount / withExpected);
                final percent = (efficiency * 100).toStringAsFixed(0);

                return Row(
                  children: [
                    _Radial(value: efficiency, label: '$percent% On-time'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Completed trips: ${trips.length}'),
                          Text('With ETA available: $withExpected'),
                          Text('On-time (<=120% of ETA): $onTimeCount'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Radial extends StatelessWidget {
  final double value; // 0..1
  final String label;
  const _Radial({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value.clamp(0.0, 1.0),
                strokeWidth: 8,
                backgroundColor: Colors.grey.shade300,
              ),
              Text('${(value * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}
