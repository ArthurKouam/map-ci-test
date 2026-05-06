enum VehicleType { voiture, moto, camion, autre }

class Vehicle {
  final String id;
  final String name; 
  final String brand;
  final String registrationNumber;
  final VehicleType type;
  final double capacity; // in m3
  final bool isVerified;
  final String? photoUrl;

  const Vehicle({
    required this.id,
    required this.name,
    required this.brand,
    required this.registrationNumber,
    required this.type,
    required this.capacity,
    this.isVerified = false,
    this.photoUrl,
  });

  String get typeLabel {
    switch (type) {
      case VehicleType.voiture: return 'Voiture';
      case VehicleType.moto: return 'Moto';
      case VehicleType.camion: return 'Camion';
      case VehicleType.autre: return 'Autre';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand,
    'registration_number': registrationNumber,
    'type': type.name,
    'capacity': capacity,
    'is_verified': isVerified,
    'photo_url': photoUrl,
  };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'],
    name: json['brand'],
    brand: json['brand'],
    registrationNumber: json['registration_number'],
    type: VehicleType.values.byName(json['type']),
    capacity: (json['capacity'] as num).toDouble(),
    isVerified: json['is_verified'] ?? false,
    photoUrl: json['photo_url'],
  );
}
