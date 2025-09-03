class Vehicle {
  final String id;
  final String number;
  final String type;
  final String status;
  final String driverName;
  final String driverId;
  final double fuelLevel;
  final double mileage;

  Vehicle({
    required this.id,
    required this.number,
    required this.type,
    required this.status,
    required this.driverName,
    required this.driverId,
    required this.fuelLevel,
    required this.mileage,
  });

  factory Vehicle.fromMap(String id, Map<String, dynamic> data) {
    return Vehicle(
      id: id,
      number: data['number'] ?? '',
      type: data['type'] ?? '',
      status: data['status'] ?? 'Active',
      driverName: data['driverName'] ?? '',
      driverId: data['driverId'] ?? '',
      fuelLevel: (data['fuelLevel'] ?? 0).toDouble(),
      mileage: (data['mileage'] ?? 0).toDouble(),
    );
  }
}
