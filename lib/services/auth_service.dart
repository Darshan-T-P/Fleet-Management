import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> _generateDriverId() async {
    final counterRef = _db.collection("id_counters").doc("drivers");

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int lastNumber = 0;
      if (snapshot.exists && snapshot.data()!["lastNumber"] != null) {
        lastNumber = snapshot.data()!["lastNumber"];
      }

      int newNumber = lastNumber + 1;
      transaction.set(counterRef, {"lastNumber": newNumber});

      // Format as DRV001, DRV002...
      return "DRV${newNumber.toString().padLeft(3, '0')}";
    });
  }

  Future<void> promoteToManager(String uid) async {
    await _db.collection("users").doc(uid).update({
      "role": "manager",
      "driverId": FieldValue.delete(),
    });
  }

  // Register new user → default role = driver
  Future<User?> registerWithEmail(
    String email,
    String password, {
    required String name,
    required String phone,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // --- Generate unique driver ID ---
      String driverId = await _generateDriverId();

      await _db.collection("users").doc(cred.user!.uid).set({
        "email": email,
        "name": name,
        "phone": phone,
        "role": "driver", // default role
        "driverId": driverId,
        "createdAt": FieldValue.serverTimestamp(),
      });

      return cred.user;
    } catch (e) {
      print("Register error: $e");
      return null;
    }
  }

  // Login
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ensure user exists in Firestore
      final docRef = _db.collection("users").doc(cred.user!.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          "email": email,
          "role": "driver", // fallback default
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      return cred.user;
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  // Get user role
  Future<String?> getUserRole(String uid) async {
    try {
      var doc = await _db.collection("users").doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['role'];
      }
      return null;
    } catch (e) {
      print("Get role error: $e");
      return null;
    }
  }

  Future<String> getDriverName(String driverId) async {
    final doc = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .get();
    return doc.data()?['name'] ?? "Unknown";
  }

  Future<String> getVehicleNumber(String vehicleId) async {
    final doc = await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(vehicleId)
        .get();
    return doc.data()?['numberPlate'] ?? "Unknown";
  }

  Future<String> generateVehicleCode(String type) async {
    final query = await FirebaseFirestore.instance
        .collection('vehicles')
        .where('type', isEqualTo: type)
        .get();

    int count = query.docs.length + 1; // next number
    String prefix = type.toUpperCase().substring(0, 3); // BUS / CAR / TRU
    return "$prefix${count.toString().padLeft(3, '0')}";
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Stream for auth state
  Stream<User?> get userStream => _auth.authStateChanges();
}
