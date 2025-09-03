import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
