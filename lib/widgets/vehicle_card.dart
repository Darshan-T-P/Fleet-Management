import 'package:flutter/material.dart';
import '../modals/vehicle.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onViewDetails;

  const VehicleCard({super.key, required this.vehicle, required this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    Color statusColor = vehicle.status == "Active" ? Colors.green : Colors.orange;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(12),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Number + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(vehicle.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(vehicle.status),
                  backgroundColor: statusColor.withOpacity(0.2),
                  labelStyle: TextStyle(color: statusColor),
                )
              ],
            ),

            Text(vehicle.type, style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 8),

            Text("Driver: ${vehicle.driverName} (${vehicle.driverId})"),

            const SizedBox(height: 8),

            // Fuel Level Bar
            Text("Fuel Level: ${vehicle.fuelLevel.toStringAsFixed(0)}%"),
            LinearProgressIndicator(
              value: vehicle.fuelLevel / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(
                vehicle.fuelLevel > 50 ? Colors.green : Colors.orange,
              ),
            ),

            const SizedBox(height: 8),

            Text("Mileage: ${vehicle.mileage} km/l"),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: onViewDetails,
              child: const Text("View Details"),
            ),
          ],
        ),
      ),
    );
  }
}
