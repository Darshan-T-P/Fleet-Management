import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddServicePage extends StatefulWidget {
  final String vehicleId;
  const AddServicePage({super.key, required this.vehicleId});

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController workCtrl = TextEditingController();
  final TextEditingController dateCtrl = TextEditingController();
  final TextEditingController odometerCtrl = TextEditingController();
  final TextEditingController costCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();

  Future<void> _saveService() async {
  if (!_formKey.currentState!.validate()) return;

  final serviceRef = FirebaseFirestore.instance
      .collection('vehicles')
      .doc(widget.vehicleId)
      .collection('serviceHistory')
      .doc();

  final serviceDate = DateTime.tryParse(dateCtrl.text.trim());

  await serviceRef.set({
    "serviceId": serviceRef.id,
    "work": workCtrl.text.trim(),
    "date": dateCtrl.text.trim(),
    "odometer": int.tryParse(odometerCtrl.text) ?? 0, // safe integer
    "cost": double.tryParse(costCtrl.text) ?? 0.0,    // safe double
    "notes": notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : "",
    "createdAt": FieldValue.serverTimestamp(),
  });

  // Calculate next service (3 months later)
  String nextService = "";
  if (serviceDate != null) {
    final next = DateTime(serviceDate.year, serviceDate.month + 3, serviceDate.day);
    nextService =
        "${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}";
  }

  // Always store Strings, never null
  await FirebaseFirestore.instance
      .collection('vehicles')
      .doc(widget.vehicleId)
      .update({
    "lastServiceDate": dateCtrl.text.trim(),
    "nextServiceDue": nextService,
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Service record added!")),
  );

  Navigator.pop(context);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Service")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: workCtrl,
                decoration: const InputDecoration(labelText: "Service Type / Work"),
                validator: (v) => v!.isEmpty ? "Enter service type" : null,
              ),
              TextFormField(
                controller: dateCtrl,
                decoration: const InputDecoration(labelText: "Service Date (YYYY-MM-DD)"),
                validator: (v) => v!.isEmpty ? "Enter service date" : null,
              ),
              TextFormField(
                controller: odometerCtrl,
                decoration: const InputDecoration(labelText: "Odometer Reading"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: costCtrl,
                decoration: const InputDecoration(labelText: "Cost"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: "Notes"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveService,
                child: const Text("Save Service"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
