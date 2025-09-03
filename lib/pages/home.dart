import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? "Unknown User";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          Row(
            children: [
              Text(
                email,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: "Logout",
                onPressed: () async {
                  await _authService.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, "/login");
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: const AdminDashboard(),
    );
  }
}
