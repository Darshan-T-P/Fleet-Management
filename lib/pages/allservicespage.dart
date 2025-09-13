import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllServicesPage extends StatelessWidget {
  const AllServicesPage({super.key});

  String safeString(dynamic value) {
    if (value == null) return 'N/A';
    if (value is Timestamp) return value.toDate().toString();
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Services")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collectionGroup('serviceHistory') // ✅ fetch services of all vehicles
            .orderBy("date", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No services yet."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.build),
                  title: Text(safeString(data['work'])),
                  subtitle: Text(
                    "Date: ${safeString(data['date'])} | "
                    "Odometer: ${safeString(data['odometer'])} km\n"
                    "Notes: ${safeString(data['notes'])}",
                  ),
                  trailing: Text("₹${safeString(data['cost'])}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
