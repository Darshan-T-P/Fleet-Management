import 'package:flutter/material.dart';

import './vehicle.dart';
import './trips.dart';

// ✅ Placeholder pages for Dashboard & Analytics
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Dashboard Page",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Analytics Page",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    VehiclesPage(),
    TripsPage(),
    AnalyticsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: _pages[_selectedIndex],

    
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            label: "Vehicles",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            label: "Trips",
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
