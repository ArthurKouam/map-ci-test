import 'dart:convert';
import '../models/vehicle.dart';
import 'local_data_service.dart';

class UserProfile {
  final String id;
  final String name;
  final String type;
  final String phone;
  final List<Vehicle> vehicles;
  final bool isVerified;

  UserProfile({
    required this.id,
    required this.name,
    required this.type,
    required this.phone,
    required this.vehicles,
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'phone': phone,
    'vehicles': vehicles.map((v) => v.toJson()).toList(),
    'is_verified': isVerified,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Determine type from 'role' (client or transporter)
    String userType = json['role'] == 'transporter' ? 'Transporteur' : 'Client';
    
    // Mock missing phone
    String mockPhone = "+237 6${(json['id'] as int) % 10}000${json['id']}";
    
    // Mock missing vehicles for transporters
    List<Vehicle> mockVehicles = [];
    if (userType == 'Transporteur') {
      mockVehicles.add(
        Vehicle(
          id: "v_${json['id']}",
          name: "Véhicule principal",
          brand: (json['id'] as int) % 2 == 0 ? "Toyota Hilux" : "Mercedes-Benz",
          registrationNumber: "LT-123-AB",
          type: (json['id'] as int) % 2 == 0 ? VehicleType.camion : VehicleType.voiture,
          capacity: 15.0,
        )
      );
    }

    return UserProfile(
      id: json['id'].toString(),
      name: json['name'],
      type: userType,
      phone: json['phone'] ?? mockPhone,
      vehicles: json['vehicles'] != null 
          ? (json['vehicles'] as List).map((v) => Vehicle.fromJson(v)).toList()
          : mockVehicles,
      isVerified: json['is_verified'] ?? false,
    );
  }
}

class UserService {
  final _localData = LocalDataService();

  Future<List<UserProfile>> getUsers() async {
    final data = await _localData.getUsers();
    return data.map((u) => UserProfile.fromJson(u)).toList();
  }

  Future<bool> registerUser(UserProfile user) async {
    return await _localData.registerUser(user.toJson());
  }
}
