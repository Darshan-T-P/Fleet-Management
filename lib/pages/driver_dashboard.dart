import 'package:flutter/material.dart';
import './vehicle.dart';
import './dashboard_page.dart';
import './trips.dart';
import './driver.dart';


class DriverAnalyticsPage extends StatelessWidget {
  final String driverId;
  const DriverAnalyticsPage({super.key, required this.driverId});

  int calculateScore(Map<String, dynamic> data) {
  int score = 100;

  final double fuel = (data['fuelConsumption'] ?? 0).toDouble();
  if (fuel > 15) score -= 10;

  if (data['tyreCondition'] == "Bad") score -= 15;

  // ✅ force accidents to int
  final int accidents = (data['accidents'] ?? 0) is int
      ? (data['accidents'] as int)
      : ((data['accidents'] ?? 0).toDouble()).round();

  if (accidents > 0) {
    score -= (accidents * 5);
  }

  if (data['brakeCondition'] == "Poor") score -= 10;

  final double mileage = (data['mileage'] ?? 0).toDouble();
  if (mileage < 8 && mileage > 0) score -= 10;

  return score.clamp(0, 100);
}

  @override
  Widget build(BuildContext context) {
    // 🔹 Dummy data for now
    final Map<String, dynamic> dummyData = {
      "name": "Driver $driverId",
      "mileage": 7.5,
      "fuelConsumption": 16,
      "tyreCondition": "Bad",
      "brakeCondition": "Good",
      "airConditioning": "Working",
      "distanceTravelled": 1200,
      "accidents": 1,
    };

    final score = calculateScore(dummyData);

    return Scaffold(
      appBar: AppBar(title: const Text("My Performance Analytics")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text("Driver: ${dummyData['name']}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("Performance Score: $score / 100",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: score > 70 ? Colors.green : Colors.red)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Performance Metrics",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("Mileage: ${dummyData['mileage']} km/l"),
                  Text("Fuel Consumption: ${dummyData['fuelConsumption']} l"),
                  Text("Tyre Condition: ${dummyData['tyreCondition']}"),
                  Text("Brake Condition: ${dummyData['brakeCondition']}"),
                  Text("AC: ${dummyData['airConditioning']}"),
                  Text("Total Distance: ${dummyData['distanceTravelled']} km"),
                  Text("Accidents: ${dummyData['accidents']}"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DriverDashboard extends StatefulWidget {
  final String driverId;
  const DriverDashboard({super.key, required this.driverId});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DriverTripsPage(driverId: widget.driverId),
      DriverAnalyticsPage(driverId: widget.driverId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: "Analytics",
          ),
        ],
      ),
    );
  }
}
