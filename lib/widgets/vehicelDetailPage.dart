import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/add_service_page.dart';

class VehicleDetailPage extends StatelessWidget {
  final String vehicleId;
  const VehicleDetailPage({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    final vehicleRef =
        FirebaseFirestore.instance.collection('vehicles').doc(vehicleId);

    String safeString(dynamic value) {
      if (value == null) return 'N/A';
      if (value is Timestamp) return value.toDate().toString().split(' ')[0];
      return value.toString();
    }

    Widget infoRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Flexible(child: Text(value, textAlign: TextAlign.right)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Vehicle Details")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: vehicleRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vehicle Basic Info
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        infoRow("Vehicle Code", safeString(data['vehicleCode'])),
                        infoRow("Type", "${safeString(data['vehicleType'])} - ${safeString(data['subType'])}"),
                        infoRow("Number Plate", safeString(data['numberPlate'])),
                        infoRow("Status", safeString(data['status'])),
                        infoRow("Odometer", "${safeString(data['odometer'])} km"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Service Info
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Service Info",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        infoRow("Last Service", safeString(data['lastServiceDate'])),
                        infoRow("Next Service Due", safeString(data['nextServiceDue'])),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Performance Info
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Performance Metrics",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        infoRow("Tyre Condition", data['performance']?['tyreCondition'] ?? 'N/A'),
                        infoRow("Air Conditioning", data['performance']?['airConditioning'] ?? 'N/A'),
                        infoRow("Brake Condition", data['performance']?['brakeCondition'] ?? 'N/A'),
                        infoRow("Mileage", "${safeString(data['performance']?['mileage'])} km/l"),
                        infoRow("Fuel Consumption", "${safeString(data['performance']?['fuelConsumption'])} L"),
                        infoRow("Distance Travelled", "${safeString(data['performance']?['distanceTravelled'])} km"),
                        infoRow("Accidents", "${safeString(data['performance']?['accidents'] ?? 0)}"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Default Driver
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: infoRow(
                      "Default Driver",
                      data['defaultDriver']?['name'] ?? 'Not Assigned',
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () async {
                    final selected = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (_) => const ChangeDriverDialog(),
                    );

                    if (selected != null) {
                      await vehicleRef.update({
                        "defaultDriver": {
                          "id": selected['id'],
                          "name": selected['name'],
                        }
                      });
                    }
                  },
                  icon: const Icon(Icons.drive_eta),
                  label: const Text("Change Driver"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                SizedBox(height:10),
                // Add this button below the Service Info Card in VehicleDetailPage
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddServicePage(vehicleId: vehicleId),
      ),
    );
  },
  icon: const Icon(Icons.add_circle_outline),
  label: const Text("Add Service"),
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
),

              ],
            ),
          );
        },
      ),
    );
  }
}

class ChangeDriverDialog extends StatelessWidget {
  const ChangeDriverDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select New Driver"),
      content: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final drivers = snapshot.data!.docs;
          if (drivers.isEmpty) return const Text("No drivers found.");

          return SizedBox(
            height: 300,
            width: 300,
            child: ListView.separated(
              itemCount: drivers.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final d = drivers[index].data() as Map<String, dynamic>;
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(d['name'] ?? 'Unnamed Driver'),
                  onTap: () {
                    Navigator.pop(context, {
                      "id": drivers[index].id,
                      "name": d['name'],
                    });
                  },
                );
              },
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}
