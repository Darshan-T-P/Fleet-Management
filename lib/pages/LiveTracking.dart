import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveTrackingPage extends StatefulWidget {
  final String tripId;

  const LiveTrackingPage({super.key, required this.tripId});

  @override
  _LiveTrackingPageState createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Tracking")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("trips")
            .doc(widget.tripId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final location = data?["currentLocation"];

          if (location != null) {
            _currentPosition = LatLng(
              location["lat"],
              location["lng"],
            );

            // Move camera smoothly when location updates
            if (_mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLng(_currentPosition!),
              );
            }
          }

          return _currentPosition == null
              ? const Center(child: Text("No location yet"))
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId("driver"),
                      position: _currentPosition!,
                      infoWindow: InfoWindow(title: "Driver"),
                    ),
                  },
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                );
        },
      ),
    );
  }
}
