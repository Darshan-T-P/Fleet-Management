import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import '../services/route_service.dart';

class VehiclesPage extends StatelessWidget {
  const VehiclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vehicles")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("vehicles").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(data['numberPlate'] ?? ""),
                  subtitle: Text("${data['driver']} • ${data['type']}"),
                  trailing: Text(
                    data['status'] ?? "",
                    style: TextStyle(
                      color: data['status'] == "Active"
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  onTap: () {
                    _openAssignDialog(context, docs[index].id, data);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openAssignDialog(
    BuildContext context,
    String vehicleId,
    Map<String, dynamic> vehicle,
  ) {
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    String? selectedDriverId;
    String? selectedDriverEmail;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Assign Trip'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: startCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Start Location',
                  ),
                ),
                TextField(
                  controller: endCtrl,
                  decoration: const InputDecoration(labelText: 'End Location'),
                ),
                const SizedBox(height: 12),
                const Text('Select Driver'),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'driver')
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData)
                      return const SizedBox(
                        height: 48,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    final drivers = snap.data!.docs;
                    return DropdownButton<String>(
                      isExpanded: true,
                      value: selectedDriverId,
                      hint: const Text('Choose driver'),
                      items: drivers.map((d) {
                        final email =
                            (d.data() as Map<String, dynamic>)['email'] ?? '';
                        return DropdownMenuItem<String>(
                          value: d.id,
                          child: Text(email),
                          onTap: () {
                            selectedDriverEmail = email;
                          },
                        );
                      }).toList(),
                      onChanged: (v) {
                        selectedDriverId = v;
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (startCtrl.text.isEmpty ||
                    endCtrl.text.isEmpty ||
                    selectedDriverId == null)
                  return;

                // naive coords for estimation; replace with geocoding in production
                final route = RouteService().estimate(
                  startLat: 12.9,
                  startLng: 77.6,
                  endLat: 13.0,
                  endLng: 77.7,
                );

                final tripRef = await FirebaseFirestore.instance
                    .collection('trips')
                    .add({
                      'start': startCtrl.text,
                      'end': endCtrl.text,
                      'driverId': selectedDriverId,
                      'driverName': selectedDriverEmail ?? 'Driver',
                      'vehicleId': vehicleId,
                      'vehicleNumber': vehicle['numberPlate'] ?? 'Unassigned',
                      'vehicleType': vehicle['type'] ?? 'NA',
                      'vehicleCode': vehicle['vehicleCode'] ?? 'NA',
                      'status': 'Scheduled',
                      'createdAt': FieldValue.serverTimestamp(),
                      'expectedDurationMin': route.durationMin,
                      'expectedDistanceKm': route.distanceKm,
                      'expectedFuelLiters': route.estimatedFuelLiters,
                      'activity': 'green',
                    });

                // notify driver via in-app notification doc
                await NotificationService().sendInAppNotification(
                  userId: selectedDriverId!,
                  type: 'trip_assignment',
                  data: {
                    'tripId': tripRef.id,
                    'start': startCtrl.text,
                    'end': endCtrl.text,
                  },
                );

                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }
}
