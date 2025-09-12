import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverTrackingService {
  final String tripId;

  DriverTrackingService(this.tripId);

  Future<void> startTracking() async {
    // Check service
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    // Check & request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied");
    }

    // 🔹 Start streaming live location
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 20, // update every 20 meters
      ),
    ).listen((Position position) async {
      print("📍 New position: ${position.latitude}, ${position.longitude}");
      try {
        await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
          "currentLocation": {
            "lat": position.latitude,
            "lng": position.longitude,
            "updatedAt": FieldValue.serverTimestamp(),
          }
        });
        print("✅ Firestore updated successfully");
      } catch (e) {
        print("🔥 Firestore update failed: $e");
      }
    });
  }
}
