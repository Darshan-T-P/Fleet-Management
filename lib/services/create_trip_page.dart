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
              // Card for trip details
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
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      _buildTextField(
                          controller: tollCostController,
                          label: "Toll Cost (₹)",
                          keyboardType: TextInputType.number),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Card for Driver selection
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
                        stream: FirebaseFirestore.instance.collection('users').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                          return DropdownButtonFormField<String>(
                            initialValue: selectedDriverId,
                            hint: const Text("Select Driver"),
                            items: snapshot.data!.docs.map((doc) {
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(doc['email']),
                                onTap: () {
                                  selectedDriverName = doc['email'];
                                },
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedDriverId = value;
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

              // Card for Vehicle selection
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

                      // Vehicle type
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                          final types = snapshot.data!.docs.map((doc) => doc['type'] as String).toSet().toList();

                          return DropdownButtonFormField<String>(
                            initialValue: selectedVehicleType,
                            hint: const Text("Select Vehicle Type"),
                            items: types.map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedVehicleType = value;
                                selectedVehicleId = null;
                                selectedVehicleNumber = null;
                                selectedVehicleCode = null;
                              });
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // Vehicles for that type
                      if (selectedVehicleType != null)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('vehicles')
                              .where('type', isEqualTo: selectedVehicleType)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                            return DropdownButtonFormField<String>(
                              initialValue: selectedVehicleId,
                              hint: const Text("Select Vehicle"),
                              items: snapshot.data!.docs.map((doc) {
                                return DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text("${doc['vehicleCode']} - ${doc['numberPlate']}"),
                                  onTap: () {
                                    selectedVehicleNumber = doc['numberPlate'];
                                    selectedVehicleCode = doc['vehicleCode'];
                                  },
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedVehicleId = value;
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

              // Create Trip Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Create Trip", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, TextInputType keyboardType = TextInputType.text}) {
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
