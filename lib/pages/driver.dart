import 'package:flutter/material.dart';
// duplicate import removed
import 'package:firebase_auth/firebase_auth.dart';
import '../services/drive_tracking.dart';
import 'driver_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverTripsPage extends StatefulWidget {
  final String driverId; // Pass this from login/session

  const DriverTripsPage({super.key, required this.driverId});

  @override
  State<DriverTripsPage> createState() => _DriverTripsPageState();
}

class _DriverTripsPageState extends State<DriverTripsPage> {
  @override
  void initState() {
    super.initState();
    _listenForAssignments();
  }

  void _listenForAssignments() {
    FirebaseFirestore.instance
        .collection('user_notifications')
        .doc(widget.driverId)
        .collection('items')
        .where('status', isEqualTo: 'new')
        .where('type', isEqualTo: 'trip_assignment')
        .snapshots()
        .listen((snapshot) {
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final tripId = data['data']?['tripId'];
            final start = data['data']?['start'];
            final end = data['data']?['end'];
            if (tripId != null) {
              _showAssignmentDialog(doc.id, tripId, start, end);
            }
          }
        });
  }
  void _showReassignDialog(
  BuildContext context,
  String tripId,
  Map<String, dynamic> tripData,
) {
  String? selectedDriverId;
  String? selectedDriverName;

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text("Reassign Trip"),
        content: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'driver')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final drivers = snapshot.data!.docs;

            return DropdownButtonFormField<String>(
              value: selectedDriverId,
              hint: const Text("Select New Driver"),
              items: drivers.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['email'] ?? "Unknown";
                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(name),
                  onTap: () {
                    selectedDriverName = name;
                  },
                );
              }).toList(),
              onChanged: (value) {
                selectedDriverId = value;
              },
            );
          },
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: const Text("Reassign"),
            onPressed: () async {
              if (selectedDriverId == null) return;

              // Update trip with new driver
              await FirebaseFirestore.instance
                  .collection('trips')
                  .doc(tripId)
                  .update({
                "driverId": selectedDriverId,
                "driverName": selectedDriverName ?? "Unassigned",
                "status": "Scheduled", // reset if needed
              });

              // Send notification to the new driver
              await FirebaseFirestore.instance
                  .collection('user_notifications')
                  .doc(selectedDriverId)
                  .collection('items')
                  .add({
                "status": "new",
                "type": "trip_assignment",
                "createdAt": FieldValue.serverTimestamp(),
                "data": {
                  "tripId": tripId,
                  "start": tripData['start'],
                  "end": tripData['end'],
                }
              });

              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Trip reassigned successfully")),
              );
            },
          ),
        ],
      );
    },
  );
}


  Future<void> _showAssignmentDialog(
    String notifId,
    String tripId,
    String? start,
    String? end,
  ) async {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('New Trip Assignment'),
          content: Text('Route: ${start ?? ''} → ${end ?? ''}'),
          actions: [
            TextButton(
              onPressed: () async {
                // decline: mark notification handled
                await FirebaseFirestore.instance
                    .collection('user_notifications')
                    .doc(widget.driverId)
                    .collection('items')
                    .doc(notifId)
                    .set({'status': 'dismissed'}, SetOptions(merge: true));
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Decline'),
            ),
            ElevatedButton(
              onPressed: () async {
                // accept: mark status and set acceptedAt
                await FirebaseFirestore.instance
                    .collection('trips')
                    .doc(tripId)
                    .set({
                      'accepted': true,
                      'acceptedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                await FirebaseFirestore.instance
                    .collection('user_notifications')
                    .doc(widget.driverId)
                    .collection('items')
                    .doc(notifId)
                    .set({'status': 'handled'}, SetOptions(merge: true));
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

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
                        icon: const Icon(Icons.person, color: Colors.black54),
                        tooltip: 'Profile',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DriverProfilePage(),
                            ),
                          );
                        },
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
                    .where('driverId', isEqualTo: widget.driverId)
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
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      final data = trip.data() as Map<String, dynamic>;

                      // statusColor removed; using activityColor instead.

                      final activityColor = _computeActivityColor(data);
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: activityColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _activityLabel(data),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: activityColor.darken(0.2),
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
                                              "startedAt":
                                                  FieldValue.serverTimestamp(),
                                            });
                                        DriverTrackingService(
                                          trip.id,
                                        ).startTracking();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Trip Started & Live Tracking Enabled",
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  if (data['status'] == "Ongoing") ...[
                                    _customButton(
                                      label: "End Trip",
                                      color: Colors.redAccent,
                                      onTap: () {
                                        _showEndTripDialog(
                                          context,
                                          trip.id,
                                          data,
                                        );
                                      },
                                    ),
                                  ],
                                  if (data['status'] == "Scheduled" || data['status'] == "Ongoing") ...[
  _customButton(
    label: "Reassign",
    color: Colors.orange,
    onTap: () {
      _showReassignDialog(context, trip.id, data);
    },
  ),
],

                                ],
                              ),

                              // Completed Trip Details
                              if (data['status'] == "Completed") ...[
                                const SizedBox(height: 12),
                                Text("Fuel Cost: ₹${data['fuelCost'] ?? 0}"),
                                Text(
                                  "Service Cost: ₹${data['serviceCost'] ?? 0}",
                                ),
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

  Widget _customButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 10, bottom: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showEndTripDialog(
    BuildContext context,
    String tripId,
    Map<String, dynamic> tripData,
  ) {
    final fuelController = TextEditingController();
    final serviceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                decoration: const InputDecoration(
                  labelText: "Service Cost (₹)",
                ),
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
                final serviceCost =
                    double.tryParse(serviceController.text) ?? 0.0;
                final tollCost = (tripData['tollCost'] ?? 0).toDouble();
                final totalCost = fuelCost + serviceCost + tollCost;

                await FirebaseFirestore.instance
                    .collection('trips')
                    .doc(tripId)
                    .update({
                      "status": "Completed",
                      "completedAt": FieldValue.serverTimestamp(),
                      "fuelCost": fuelCost,
                      "serviceCost": serviceCost,
                      "totalCost": totalCost,
                    });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Trip Completed! Total Cost: ₹$totalCost"),
                  ),
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

extension _Activity on _DriverTripsPageState {
  Color _computeActivityColor(Map<String, dynamic> data) {
    final status = (data['status'] ?? 'Scheduled') as String;
    if (status == 'Completed') return Colors.blue;
    if (status == 'Ongoing') {
      final updatedAt = (data['currentLocation']?['updatedAt']);
      final ts = updatedAt is Timestamp ? updatedAt.toDate() : DateTime.now();
      final minutesSince = DateTime.now().difference(ts).inMinutes;
      // Yellow if no location update for > expected threshold (10 min), else Green
      return minutesSince > 10 ? Colors.yellow.shade700 : Colors.green.shade600;
    }
    return Colors.green.shade600; // Scheduled treated as green (on schedule)
  }

  String _activityLabel(Map<String, dynamic> data) {
    final status = (data['status'] ?? 'Scheduled') as String;
    if (status == 'Completed') return 'Completed';
    if (status == 'Ongoing') {
      final updatedAt = (data['currentLocation']?['updatedAt']);
      final ts = updatedAt is Timestamp ? updatedAt.toDate() : DateTime.now();
      final minutesSince = DateTime.now().difference(ts).inMinutes;
      return minutesSince > 10 ? 'Idle/Resting' : 'On Schedule';
    }
    return 'Scheduled';
  }
}
