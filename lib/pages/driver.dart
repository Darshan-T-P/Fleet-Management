import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/drive_tracking.dart';

class DriverTripsPage extends StatelessWidget {
  final String driverId; // Pass this from login/session

  const DriverTripsPage({super.key, required this.driverId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "My Trips",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Row(
                    children: [
                      if (user != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            user.email ?? "",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.black54),
                        tooltip: "Logout",
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Trip List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('trips')
                    .where('driverId', isEqualTo: driverId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final trips = snapshot.data!.docs;

                  if (trips.isEmpty) {
                    return const Center(
                        child: Text(
                      "No trips assigned yet.",
                      style: TextStyle(fontSize: 16, color: Colors.black38),
                    ));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      final data = trip.data() as Map<String, dynamic>;

                      Color statusColor;
                      if (data['status'] == "Scheduled") {
                        statusColor = Colors.grey.shade400;
                      } else if (data['status'] == "Ongoing") {
                        statusColor = Colors.orange.shade400;
                      } else {
                        statusColor = Colors.green.shade400;
                      }

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Route & Status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      "${data['start']} → ${data['end']}",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF222222),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      data['status'] ?? "Scheduled",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: statusColor.darken(0.2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Vehicle: ${data['vehicleNumber']} (${data['vehicleType'] ?? 'N/A'})",
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Action Buttons
                              Row(
                                children: [
                                  if (data['status'] == "Scheduled")
                                    _customButton(
                                      label: "Start Trip",
                                      color: Colors.blueAccent,
                                      onTap: () async {
                                        await FirebaseFirestore.instance
                                            .collection('trips')
                                            .doc(trip.id)
                                            .update({
                                          "status": "Ongoing",
                                          "startedAt": FieldValue.serverTimestamp(),
                                        });
                                        DriverTrackingService(trip.id).startTracking();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Trip Started & Live Tracking Enabled"),
                                          ),
                                        );
                                      },
                                    ),
                                  if (data['status'] == "Ongoing") ...[
                                    _customButton(
                                      label: "End Trip",
                                      color: Colors.redAccent,
                                      onTap: () {
                                        _showEndTripDialog(context, trip.id, data);
                                      },
                                    ),
                                  ],
                                ],
                              ),

                              // Completed Trip Details
                              if (data['status'] == "Completed") ...[
                                const SizedBox(height: 12),
                                Text("Fuel Cost: ₹${data['fuelCost'] ?? 0}"),
                                Text("Service Cost: ₹${data['serviceCost'] ?? 0}"),
                                Text("Toll Cost: ₹${data['tollCost'] ?? 0}"),
                                Text("Total Cost: ₹${data['totalCost'] ?? 0}"),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customButton({required String label, required Color color, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(right: 10, bottom: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Complete Trip"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fuelController,
                decoration: const InputDecoration(labelText: "Fuel Cost (₹)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: serviceController,
                decoration: const InputDecoration(labelText: "Service Cost (₹)"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Submit"),
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

// Extension to darken colors
extension ColorBrightness on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
