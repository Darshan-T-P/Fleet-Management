import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key});

  @override
  _CreateTripPageState createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();
  final TextEditingController distanceController = TextEditingController();
  final TextEditingController tollCostController = TextEditingController();

  String? selectedDriverId;
  String? selectedDriverName;

  String? selectedVehicleType;
  String? selectedVehicleId;
  String? selectedVehicleNumber;
  String? selectedVehicleCode;
  String? selectedVehicleSubType;

  // Vehicle type -> subtypes
  static const Map<String, List<String>> _vehicleSubtypes = {
    'Car':['Sedan', 'SUV', 'Hatchback', 'MPV', 'Coupe', 'Convertible'],
    'Bus': ['City', 'School', 'Tourist', 'Luxury'],
    'Lorry / Truck': [
      'General cargo',
      'Tipper',
      'Container',
      'Refrigerated',
      'Tanker',
      'Flatbed',
      'Bulk carrier',
      'Curtain-side',
      'Car carrier',
      'Logging',
      'Garbage',
    ],
  };

  // Vehicle type -> what it carries
  static const Map<String, String> _vehicleCarries = {
    'Car': 'Passengers (commuters, students, tourists)',
    'Bus': 'Passengers (commuters, students, tourists)',
    'Lorry / Truck':
        'Goods like sand, gravel, machinery, perishable food, fuel, chemicals, waste, etc.',
  };

  String _carriesForType(String? type) {
    final t = (type ?? '').trim().toLowerCase();
    if (t.isEmpty) return '—';
    if (t == 'bus') return _vehicleCarries['Bus']!;
    if (t.contains('lorry') || t.contains('truck')) return _vehicleCarries['Lorry / Truck']!;
    return _vehicleCarries[type ?? ''] ?? '—';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Create Trip"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Trip details card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(controller: startController, label: "Start Location"),
                      const SizedBox(height: 12),
                      _buildTextField(controller: endController, label: "End Location"),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: distanceController,
                        label: "Distance (km)",
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: tollCostController,
                        label: "Toll Cost (₹)",
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Vehicle selection card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Select Vehicle", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      // Vehicle type dropdown
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                          // Extract types safely
                          final types = snapshot.data!.docs
                              .map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return data['type']?.toString() ?? '';
                              })
                              .where((t) => t.isNotEmpty)
                              .toSet()
                              .toList();

                          return DropdownButtonFormField<String>(
                            value: selectedVehicleType,
                            hint: const Text("Select Vehicle Type"),
                            items: types.map((type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            )).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedVehicleType = value;
                                selectedVehicleId = null;
                                selectedVehicleNumber = null;
                                selectedVehicleCode = null;
                                selectedVehicleSubType = null;

                                // Reset driver selection if vehicle changes
                                selectedDriverId = null;
                                selectedDriverName = null;
                              });
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // Vehicle sub-type dropdown
                      if (selectedVehicleType != null && _vehicleSubtypes.containsKey(selectedVehicleType))
                        DropdownButtonFormField<String>(
                          value: selectedVehicleSubType,
                          hint: const Text('Select Sub-type'),
                          items: (_vehicleSubtypes[selectedVehicleType] ?? [])
                              .map((sub) => DropdownMenuItem<String>(
                                    value: sub,
                                    child: Text(sub),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => selectedVehicleSubType = v),
                        ),

                      if (selectedVehicleType != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Carries: ${_carriesForType(selectedVehicleType)}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Vehicle selection based on type
                      if (selectedVehicleType != null)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('vehicles')
                              .where('type', isEqualTo: selectedVehicleType)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                            return DropdownButtonFormField<String>(
                              value: selectedVehicleId,
                              hint: const Text("Select Vehicle"),
                              items: snapshot.data!.docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text("${data['vehicleCode'] ?? 'NA'} - ${data['numberPlate'] ?? 'NA'}"),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedVehicleId = value;

                                  if (value != null) {
                                    final doc = snapshot.data!.docs.firstWhere((d) => d.id == value);
                                    final data = doc.data() as Map<String, dynamic>;
                                    selectedVehicleNumber = data['numberPlate'] ?? 'NA';
                                    selectedVehicleCode = data['vehicleCode'] ?? 'NA';
                                    selectedVehicleSubType = data['subType'] ?? selectedVehicleSubType;

                                    // Automatically set default driver
                                    final defaultDriver = data['defaultDriver'] as Map<String, dynamic>?;
                                    if (defaultDriver != null) {
                                      selectedDriverId = defaultDriver['id'];
                                      selectedDriverName = defaultDriver['name'];
                                    }
                                  }
                                });
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Driver selection card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Select Driver", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('role', isEqualTo: 'driver')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                          return DropdownButtonFormField<String>(
                            value: selectedDriverId,
                            hint: const Text("Select Driver"),
                            items: snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final email = data['email'] ?? 'Unnamed Driver';
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(email),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedDriverId = value;
                                if (value != null) {
                                  final doc = snapshot.data!.docs.firstWhere((d) => d.id == value);
                                  selectedDriverName = doc['email'];
                                }
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Create Trip button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    "Create Trip",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  void _createTrip() async {
    if (startController.text.isEmpty ||
        endController.text.isEmpty ||
        selectedDriverId == null ||
        selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('trips').add({
      "start": startController.text,
      "end": endController.text,
      "driverId": selectedDriverId,
      "driverName": selectedDriverName ?? "Unassigned",
      "vehicleId": selectedVehicleId,
      "vehicleNumber": selectedVehicleNumber ?? "Unassigned",
      "vehicleCode": selectedVehicleCode ?? "NA",
      "vehicleType": selectedVehicleType ?? "NA",
      "vehicleSubType": selectedVehicleSubType ?? "NA",
      "carries": _carriesForType(selectedVehicleType),
      "status": "Scheduled",
      "distance": int.tryParse(distanceController.text) ?? 0,
      "tollCost": int.tryParse(tollCostController.text) ?? 0,
      "createdAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Trip Created Successfully!")),
    );

    Navigator.pop(context);
  }
}
