import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'pages/auth_screen.dart';
import 'pages/home.dart';     // manager/admin dashboard
import 'pages/driver.dart'; // driver dashboard

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AuthScreen();

          final user = snapshot.data!;
          return FutureBuilder<String?>(
            future: _authService.getUserRole(user.uid),
            builder: (context, roleSnap) {
              if (!roleSnap.hasData) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (roleSnap.data == "manager") {
                return const HomeScreen(); // manager/admin dashboard
              } else {
                return DriverTripsPage(driverId: user.uid); // driver dashboard
              }
            },
          );
        },
      ),
    );
  }
}
