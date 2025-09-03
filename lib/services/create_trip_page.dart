import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateTripPage extends StatefulWidget {
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
      appBar: AppBar(title: Text("Create Trip")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            /// Start + End
            TextField(
              controller: startController,
              decoration: InputDecoration(labelText: "Start Location"),
            ),
            TextField(
              controller: endController,
              decoration: InputDecoration(labelText: "End Location"),
            ),
            TextField(
              controller: distanceController,
              decoration: InputDecoration(labelText: "Distance (km)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: tollCostController,
              decoration: InputDecoration(labelText: "Toll Cost"),
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 16),

            /// Drivers Dropdown
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                return DropdownButtonFormField<String>(
                  value: selectedDriverId,
                  hint: Text("Select Driver"),
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

            SizedBox(height: 16),

            /// Vehicle Type Dropdown
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();

                /// get unique vehicle types
                final types = snapshot.data!.docs
                    .map((doc) => doc['type'] as String)
                    .toSet()
                    .toList();

                return DropdownButtonFormField<String>(
                  value: selectedVehicleType,
                  hint: Text("Select Vehicle Type"),
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

            SizedBox(height: 16),

            /// Vehicles of that type
            if (selectedVehicleType != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('vehicles')
                    .where('type', isEqualTo: selectedVehicleType)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  return DropdownButtonFormField<String>(
                    value: selectedVehicleId,
                    hint: Text("Select Vehicle"),
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

            SizedBox(height: 20),

            /// Create Trip Button
            ElevatedButton(
              child: Text("Create Trip"),
              onPressed: () async {
                if (startController.text.isEmpty ||
                    endController.text.isEmpty ||
                    selectedDriverId == null ||
                    selectedVehicleId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please fill all required fields")),
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
                  SnackBar(content: Text("Trip Created Successfully!")),
                );

                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
