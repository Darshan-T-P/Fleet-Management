import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController vehicleCodeCtrl = TextEditingController();
  final TextEditingController numberPlateCtrl = TextEditingController();
  final TextEditingController insuranceExpiryCtrl = TextEditingController();
  final TextEditingController fitnessExpiryCtrl = TextEditingController();

  String? selectedType;
  String? selectedSubType;
  String? selectedDriverId;
  String? selectedDriverName;

  final List<String> vehicleTypes = ["Truck", "Bus", "Car", "Mini Truck"];
  final Map<String, List<String>> subTypes = {
    "Truck": ["Container", "Tipper", "Tanker"],
    "Bus": ["Sleeper", "Mini Bus"],
    "Car": ["Sedan", "SUV", "Hatchback"],
    "Mini Truck": ["Pickup", "Delivery Van"]
  };

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    final doc = FirebaseFirestore.instance.collection('vehicles').doc();

    await doc.set({
      "vehicleId": doc.id,
      "vehicleType": selectedType,
      "subType": selectedSubType,
      "vehicleCode": vehicleCodeCtrl.text.trim(),
      "numberPlate": numberPlateCtrl.text.trim(),
      "status": "Available",
      "defaultDriver": {
        "id": selectedDriverId,
        "name": selectedDriverName,
      },
      "insuranceExpiry": insuranceExpiryCtrl.text.trim(),
      "fitnessExpiry": fitnessExpiryCtrl.text.trim(),
      "createdAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vehicle Added Successfully!")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Vehicle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Vehicle Type"),
                items: vehicleTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                value: selectedType,
                onChanged: (v) {
                  setState(() {
                    selectedType = v;
                    selectedSubType = null;
                  });
                },
                validator: (v) => v == null ? "Select type" : null,
              ),
              if (selectedType != null)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Sub Type"),
                  items: subTypes[selectedType]!
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  value: selectedSubType,
                  onChanged: (v) => setState(() => selectedSubType = v),
                  validator: (v) => v == null ? "Select subtype" : null,
                ),
              TextFormField(
                controller: vehicleCodeCtrl,
                decoration: const InputDecoration(labelText: "Vehicle Code"),
                validator: (v) =>
                    v!.isEmpty ? "Vehicle code required" : null,
              ),
              // 👇 Driver Dropdown (with Firestore fetch)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final driverDocs = snapshot.data!.docs;
                  if (driverDocs.isEmpty) {
                    return const Text(
                        "No drivers found. Please add drivers first.");
                  }

                  return DropdownButtonFormField<String>(
                    value: selectedDriverId,
                    items: driverDocs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(d['name'] ?? 'Unnamed Driver'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      final driver =
                          driverDocs.firstWhere((d) => d.id == value);
                      setState(() {
                        selectedDriverId = driver.id;
                        selectedDriverName =
                            (driver.data() as Map<String, dynamic>)['name'];
                      });
                    },
                    decoration: const InputDecoration(
                        labelText: "Assign Default Driver"),
                    validator: (v) => v == null ? "Select a driver" : null,
                  );
                },
              ),
              TextFormField(
                controller: numberPlateCtrl,
                decoration:
                    const InputDecoration(labelText: "Number Plate"),
                validator: (v) =>
                    v!.isEmpty ? "Number plate required" : null,
              ),
              TextFormField(
                controller: insuranceExpiryCtrl,
                decoration: const InputDecoration(
                    labelText: "Insurance Expiry (YYYY-MM-DD)"),
                validator: (v) =>
                    v!.isEmpty ? "Insurance expiry required" : null,
              ),
              TextFormField(
                controller: fitnessExpiryCtrl,
                decoration: const InputDecoration(
                    labelText: "Fitness Expiry (YYYY-MM-DD)"),
                validator: (v) =>
                    v!.isEmpty ? "Fitness expiry required" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveVehicle,
                child: const Text("Save Vehicle"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
