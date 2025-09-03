import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverTripsPage extends StatelessWidget {
  final String driverId; // Pass this from login/session

  DriverTripsPage({required this.driverId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("My Trips"),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  user.email ?? "",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .where('driverId', isEqualTo: driverId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final trips = snapshot.data!.docs;

          if (trips.isEmpty) {
            return Center(child: Text("No trips assigned yet."));
          }

          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              final data = trip.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.all(12),
                child: ListTile(
                  title: Text("${data['start']} → ${data['end']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Vehicle: ${data['vehicleNumber']}"),
                      Text("Status: ${data['status']}"),
                      // Text("Vehicle Type: ${data['vehicleType']}")
                    ],
                  ),
                  trailing: data['status'] == "Scheduled"
                      ? ElevatedButton(
                          child: Text("Start Trip"),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('trips')
                                .doc(trip.id)
                                .update({
                              "status": "Ongoing",
                              "startedAt": FieldValue.serverTimestamp(),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Trip Started!")),
                            );
                          },
                        )
                      : data['status'] == "Ongoing"
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: Text("End Trip"),
                              onPressed: () async {
                                _showEndTripDialog(context, trip.id, data);
                              },
                            )
                          : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEndTripDialog(BuildContext context, String tripId, Map<String, dynamic> tripData) {
    final fuelController = TextEditingController();
    final serviceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Complete Trip"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fuelController,
                decoration: InputDecoration(labelText: "Fuel Cost (₹)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: serviceController,
                decoration: InputDecoration(labelText: "Service Cost (₹)"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text("Submit"),
              onPressed: () async {
                final fuelCost = double.tryParse(fuelController.text) ?? 0.0;
                final serviceCost = double.tryParse(serviceController.text) ?? 0.0;
                final tollCost = (tripData['tollCost'] ?? 0).toDouble();

                final totalCost = fuelCost + serviceCost + tollCost;

                await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
                  "status": "Completed",
                  "completedAt": FieldValue.serverTimestamp(),
                  "fuelCost": fuelCost,
                  "serviceCost": serviceCost,
                  "totalCost": totalCost,
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Trip Completed! Total Cost: ₹$totalCost")),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
