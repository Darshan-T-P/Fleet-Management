import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleet_management/widgets/vehicelDetailPage.dart';
import 'package:fleet_management/widgets/add_vehicle.dart';
import 'package:fleet_management/pages/allservicespage.dart';

class VehicleListPage extends StatelessWidget {
  const VehicleListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vehicles"),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AllServicesPage()),
            );
          },
          icon: const Icon(Icons.list),
        ),
      ],),
      
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No vehicles yet"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              String status = data['status'] ?? "Unknown";
              String nextService = data['nextServiceDue'] ?? "N/A";

              Color statusColor;
              switch (status) {
                case "Available":
                  statusColor = Colors.green;
                  break;
                case "In Trip":
                  statusColor = Colors.orange;
                  break;
                case "In Service":
                  statusColor = Colors.red;
                  break;
                default:
                  statusColor = Colors.grey;
              }

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text("${data['vehicleType']} - ${data['numberPlate']}"),
                  subtitle: Text(
                    "Status: $status | Next Service: $nextService",
                  ),
                  trailing: Icon(Icons.circle, color: statusColor, size: 14),
                  onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => VehicleDetailPage(
        vehicleId: docs[index].id, // ✅ Always present
      ),
    ),
  );
},

                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddVehiclePage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

