import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("FleetPro Dashboard"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Quick stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _dashboardCard(
                    title: "Total Trips",
                    stream: FirebaseFirestore.instance.collection('trips').snapshots(),
                    icon: Icons.directions_car,
                    color: Colors.blueAccent,
                  ),
                  _dashboardCard(
                    title: "Ongoing Trips",
                    stream: FirebaseFirestore.instance
                        .collection('trips')
                        .where('status', isEqualTo: 'Ongoing')
                        .snapshots(),
                    icon: Icons.timer,
                    color: Colors.orangeAccent,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _dashboardCard(
                    title: "Completed Trips",
                    stream: FirebaseFirestore.instance
                        .collection('trips')
                        .where('status', isEqualTo: 'Completed')
                        .snapshots(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                  _dashboardCard(
                    title: "Total Vehicles",
                    stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
                    icon: Icons.local_shipping,
                    color: Colors.purpleAccent,
                  ),
                ],
              ),           
             

              const SizedBox(height: 24),

              // Optional: Recent Trips
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Recent Trips",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('trips')
                    .orderBy('createdAt', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final trips = snapshot.data!.docs;
                  return Column(
                    children: trips.map((trip) {
                      final data = trip.data() as Map<String, dynamic>;
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text("${data['start']} → ${data['end']}"),
                          subtitle: Text(
                              "Driver: ${data['driverName'] ?? 'N/A'} | Vehicle: ${data['vehicleNumber'] ?? 'N/A'}"),
                          trailing: Text(
                            data['status'] ?? 'Scheduled',
                            style: TextStyle(
                                color: data['status'] == 'Ongoing'
                                    ? Colors.orange
                                    : data['status'] == 'Completed'
                                        ? Colors.green
                                        : Colors.grey,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardCard({
    required String title,
    required Stream<QuerySnapshot> stream,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(icon, size: 36, color: color),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$count",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
