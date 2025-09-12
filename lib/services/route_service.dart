import 'dart:math';

class RouteOption {
  final List<List<double>> polyline; // simple lat,lng pairs for demo
  final double distanceKm;
  final double durationMin;
  final double estimatedFuelLiters;
  final String label;

  RouteOption({
    required this.polyline,
    required this.distanceKm,
    required this.durationMin,
    required this.estimatedFuelLiters,
    required this.label,
  });
}

class RouteService {
  // Very simplified estimator. In real apps use Directions + traffic + vehicle profile.
  RouteOption estimate({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    double vehicleKmPerLiter = 12.0,
    double trafficFactor = 1.0,
  }) {
    final distanceKm = _haversine(startLat, startLng, endLat, endLng);
    final durationMin =
        distanceKm / 40.0 * 60.0 * trafficFactor; // assume 40km/h avg
    final fuelLiters = (distanceKm / vehicleKmPerLiter) * trafficFactor;

    return RouteOption(
      polyline: [
        [startLat, startLng],
        [endLat, endLng],
      ],
      distanceKm: distanceKm,
      durationMin: durationMin,
      estimatedFuelLiters: fuelLiters,
      label: 'Suggested',
    );
  }

  List<RouteOption> compareAlternatives({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    double vehicleKmPerLiter = 12.0,
  }) {
    // Base, slight detour, longer highway with better economy
    final base = estimate(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
      vehicleKmPerLiter: vehicleKmPerLiter,
      trafficFactor: 1.0,
    );
    final detour = estimate(
      startLat: startLat + 0.02,
      startLng: startLng + 0.02,
      endLat: endLat,
      endLng: endLng,
      vehicleKmPerLiter: vehicleKmPerLiter,
      trafficFactor: 1.15,
    );
    final highway = estimate(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng + 0.03,
      vehicleKmPerLiter: vehicleKmPerLiter * 1.1, // better economy
      trafficFactor: 0.9, // usually faster
    );
    return [
      base,
      RouteOption(
        polyline: detour.polyline,
        distanceKm: detour.distanceKm * 1.05,
        durationMin: detour.durationMin,
        estimatedFuelLiters: detour.estimatedFuelLiters,
        label: 'Detour',
      ),
      RouteOption(
        polyline: highway.polyline,
        distanceKm: highway.distanceKm * 1.1,
        durationMin: highway.durationMin * 0.95,
        estimatedFuelLiters: highway.estimatedFuelLiters * 0.9,
        label: 'Highway',
      ),
    ];
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);
}
